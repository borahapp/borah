-- DV-08 - Administration Module (auditoria)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Tabela append-only (decisao do DV-08): somente INSERT e SELECT sao
-- permitidos - nem mesmo super_admin pode alterar ou apagar um registro
-- de auditoria. Modo "best effort": a acao administrativa e executada e,
-- em seguida, o log e gravado - sem transacao distribuida entre as duas
-- escritas.

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references auth.users (id) on delete restrict,
  action text not null,
  entity text not null,
  entity_id uuid not null,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_entity_idx on public.audit_logs (entity, entity_id);

alter table public.audit_logs enable row level security;

-- INSERT: qualquer administrador pode registrar uma auditoria da propria acao.
create policy "audit_logs_insert_own_admin"
  on public.audit_logs for insert
  to authenticated
  with check (auth.uid() = actor_id and public.is_admin(auth.uid()));

-- SELECT: qualquer administrador consulta o historico de auditoria.
create policy "audit_logs_select_admin"
  on public.audit_logs for select
  to authenticated
  using (public.is_admin(auth.uid()));

-- UPDATE/DELETE: nao implementados - append-only, inclusive para
-- super_admin (decisao explicita do DV-08).
