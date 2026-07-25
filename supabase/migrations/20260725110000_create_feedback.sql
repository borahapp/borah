-- RC-03E - In-App Feedback Module
--
-- Tabela de feedback enviado dentro do app (RC-03E). Registro de
-- auditoria simples, sem workflow de moderação/triagem nesta rodada
-- (nenhum painel administrativo é criado aqui - mesma decisão já usada
-- em public.comment_reports antes do DV-08 existir).
--
-- Estrutura pensada para expansão futura: `status` existe desde já
-- (default 'new') para permitir um fluxo de triagem futuro sem
-- migration adicional; `screen_context`/`app_version`/`environment`
-- dão contexto técnico sem precisar de uma tabela separada.
--
-- RLS: usuário só insere e só vê o PRÓPRIO feedback
-- (`feedback_select_own`/`feedback_insert_own`); administrador vê todos
-- (`feedback_select_admin`, mesmo padrão de `comment_reports_select_admin`
-- - permissiva, soma-se à policy de dono em vez de substituí-la). Nenhum
-- usuário comum enxerga feedback de outro usuário. UPDATE/DELETE não
-- implementados nesta rodada (registro imutável, como comment_reports) -
-- uma policy de UPDATE para administradores fica para quando houver um
-- painel de triagem real.
--
-- ATENCAO: assim como as demais migracoes do projeto, esta foi escrita
-- e revisada estaticamente, sem validacao contra uma instancia real do
-- Supabase/Postgres (ver AR-06/EX-01B).

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  message text not null,
  screen_context text,
  app_version text,
  environment text,
  status text not null default 'new' check (status in ('new', 'reviewed', 'resolved')),
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

-- SELECT: o próprio autor.
create policy "feedback_select_own"
  on public.feedback for select
  to authenticated
  using (auth.uid() = user_id);

-- SELECT: qualquer administrador vê todos (soma-se à policy acima -
-- RLS permissiva, não substitui).
create policy "feedback_select_admin"
  on public.feedback for select
  to authenticated
  using (public.is_admin(auth.uid()));

-- INSERT: somente o próprio usuário, e só em nome de si mesmo.
create policy "feedback_insert_own"
  on public.feedback for insert
  to authenticated
  with check (auth.uid() = user_id);

-- UPDATE/DELETE: não implementados nesta rodada (registro imutável).

-- GRANT concedido já nesta migração (lição da correção de GRANT da
-- FASE 5/6 - sem GRANT de tabela, toda policy de RLS é inalcançável).
grant select, insert on public.feedback to authenticated;
