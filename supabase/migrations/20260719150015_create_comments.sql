-- DV-07 - Social Module (comentarios)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Soft delete via deleted_at (diferente de review_likes/favorites) - um
-- comentario denunciado (comment_reports) deve continuar existindo para
-- auditoria futura do DV-08, mesmo apos o autor "excluir" o comentario.
-- ON DELETE RESTRICT em review_id/user_id: comentario e conteudo com
-- valor, mesmo raciocinio de reviews (nao review_likes/favorites).

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references public.reviews (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete restrict,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index comments_review_id_idx on public.comments (review_id);

alter table public.comments enable row level security;

-- SELECT: aberta a autenticados (comentarios em avaliacoes publicas).
create policy "comments_select_authenticated"
  on public.comments for select
  to authenticated
  using (true);

create policy "comments_insert_own"
  on public.comments for insert
  to authenticated
  with check (auth.uid() = user_id);

-- UPDATE cobre tanto a edicao de `content` quanto a exclusao logica
-- (`deleted_at`) - RLS por si so nao diferencia qual coluna mudou, entao
-- esta policy garante apenas autoria. A janela de 15 minutos para EDITAR
-- o texto (decisao do DV-07 - nao se aplica a exclusao, que RN nenhuma
-- limita no tempo) e reforcada pelo trigger abaixo, que roda no banco,
-- nao no cliente.
create policy "comments_update_own"
  on public.comments for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create function public.enforce_comment_edit_window()
returns trigger
language plpgsql
as $$
begin
  if new.content is distinct from old.content
     and now() - old.created_at > interval '15 minutes' then
    raise exception 'A janela de edição do comentário expirou.';
  end if;
  return new;
end;
$$;

create trigger enforce_comment_edit_window_trigger
  before update on public.comments
  for each row execute procedure public.enforce_comment_edit_window();

-- Reutiliza a funcao compartilhada criada em
-- 20260718212615_add_set_updated_at_function.sql - nao recriar por tabela.
create trigger set_comments_updated_at
  before update on public.comments
  for each row execute procedure public.set_updated_at();
