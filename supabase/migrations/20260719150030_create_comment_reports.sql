-- DV-07 - Social Module (denuncias de comentario)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Registro de auditoria simples, sem workflow de moderacao (decisao do
-- DV-07 - o DV-08 consumira esses registros futuramente). ON DELETE
-- RESTRICT: denuncia e registro de auditoria, nao pode desaparecer.

create table public.comment_reports (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.comments (id) on delete restrict,
  reported_by uuid not null references auth.users (id) on delete restrict,
  reason text not null,
  created_at timestamptz not null default now(),

  constraint comment_reports_unique unique (comment_id, reported_by)
);

alter table public.comment_reports enable row level security;

-- SELECT/INSERT: somente o proprio autor da denuncia - nao existe papel
-- de administrador ainda (DV-08 nao implementado); quando existir, uma
-- policy propria sera adicionada para acesso administrativo.
create policy "comment_reports_select_own"
  on public.comment_reports for select
  to authenticated
  using (auth.uid() = reported_by);

create policy "comment_reports_insert_own"
  on public.comment_reports for insert
  to authenticated
  with check (auth.uid() = reported_by);

-- UPDATE/DELETE: nao implementados (denuncia e imutavel).
