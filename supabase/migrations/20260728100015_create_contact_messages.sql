-- BETA-11C - Mensagens enviadas pelo formulário de Contato/Suporte do
-- site institucional.
--
-- Mesmo modelo de acesso de beta_waitlist (ver comentário completo em
-- 20260728100000_create_beta_waitlist.sql): só o service_role, via
-- Edge Function website-form-submit, grava nesta tabela. O papel
-- `anon` não recebe nenhum privilégio - mantém a invariante "anon não
-- recebe nada" já documentada em
-- 20260720130000_grant_authenticated_privileges.sql.
--
-- `status` existe desde já para permitir um fluxo de triagem manual
-- (via Supabase Studio) sem migration adicional - mesmo raciocínio já
-- usado em public.feedback (RC-03E).
--
-- ATENÇÃO: escrita e revisada estaticamente, sem validação contra uma
-- instância real do Supabase/Postgres (Docker indisponível neste
-- ambiente - ver AR-06/EX-01B).

create table public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  subject text,
  message text not null,
  status text not null default 'new'
    check (status in ('new', 'read', 'archived')),
  created_at timestamptz not null default now()
);

alter table public.contact_messages enable row level security;

-- Nenhuma policy é criada para `anon`/`authenticated` de propósito -
-- ver justificativa em beta_waitlist.
