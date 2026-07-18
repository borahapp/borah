-- DV-04 - Reviews Module (curtidas)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Tabela separada de curtidas (nao armazena comentarios - DV-07 e o unico
-- dono de comentarios). `reviews.likes_count` e mantido consistente pelo
-- trigger de recalculo criado em
-- 20260718230545_create_reviews_average_rating_trigger.sql.
--
-- ON DELETE CASCADE (diferente do RESTRICT usado em reviews.restaurant_id/
-- user_id): uma curtida nao tem sentido sem sua avaliacao/usuario de
-- origem, entao e removida junto - nao ha necessidade de proteger a
-- integridade referencial aqui como ha para restaurantes/usuarios.

create table public.review_likes (
  review_id uuid not null references public.reviews (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),

  constraint review_likes_pkey primary key (review_id, user_id)
);

alter table public.review_likes enable row level security;

-- SELECT: qualquer usuario autenticado (DV-04).
create policy "review_likes_select_authenticated"
  on public.review_likes for select
  to authenticated
  using (true);

-- INSERT: somente o proprio usuario pode curtir em seu nome.
create policy "review_likes_insert_own"
  on public.review_likes for insert
  to authenticated
  with check (auth.uid() = user_id);

-- DELETE: somente o proprio usuario pode descurtir.
create policy "review_likes_delete_own"
  on public.review_likes for delete
  to authenticated
  using (auth.uid() = user_id);
