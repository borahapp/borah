-- BETA-11C - Lista de espera do Beta Fechado (captada pelo site
-- institucional em www.appborah.com.br).
--
-- Fluxo de escrita, decidido em revisão de arquitetura: Browser ->
-- Cloudflare Turnstile -> Edge Function (website-form-submit,
-- service_role) -> INSERT. O papel `anon` NÃO recebe nenhum privilégio
-- nesta tabela - mantém a invariante já documentada em
-- 20260720130000_grant_authenticated_privileges.sql ("anon não recebe
-- nada - nenhuma policy do projeto concede acesso a anon"). Toda
-- validação de bot (Turnstile, honeypot, tempo mínimo de
-- preenchimento) e de e-mail duplicado acontece na Edge Function antes
-- do INSERT, que roda com service_role e portanto ignora RLS.
--
-- Semântica de `status` (curado manualmente via Supabase Studio nesta
-- rodada - não existe painel administrativo no app para isso ainda):
--   pending   -> acabou de entrar na lista de espera (estado inicial)
--   invited   -> recebeu o convite por e-mail para o Beta Fechado
--   confirmed -> aceitou o convite e efetivamente criou a conta no app
--   declined  -> pediu para sair da lista, ou o convite foi recusado
--
-- `source` documenta a origem do cadastro para medir campanhas futuras
-- sem precisar de migration nova. Não é restringido por CHECK (para
-- não travar novas origens ainda não previstas); valores esperados
-- nesta fase: 'website', 'instagram', 'linkedin', 'qr_code', 'manual',
-- 'friend', 'google', 'closed_beta'.
--
-- ATENÇÃO: assim como as demais migrations do projeto, esta foi
-- escrita e revisada estaticamente, sem validação contra uma instância
-- real do Supabase/Postgres (Docker indisponível neste ambiente - ver
-- AR-06/EX-01B).

create table public.beta_waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  name text,
  source text not null default 'website',
  status text not null default 'pending'
    check (status in ('pending', 'invited', 'confirmed', 'declined')),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  invited_at timestamptz,
  notes text
);

-- Dedup case-insensitive sem depender da extensão citext (não usada em
-- nenhuma outra tabela do projeto) - a Edge Function traduz a
-- violação deste índice (23505) em uma mensagem amigável de "e-mail
-- já cadastrado" para quem preencheu o formulário.
create unique index beta_waitlist_email_lower_idx
  on public.beta_waitlist (lower(email));

alter table public.beta_waitlist enable row level security;

-- Nenhuma policy é criada para `anon`/`authenticated` de propósito:
-- só o service_role (usado pela Edge Function website-form-submit)
-- acessa esta tabela. Sem GRANT/policy para `anon`, qualquer tentativa
-- de acesso direto via API pública (bypassando a Edge Function e o
-- Turnstile) é rejeitada antes mesmo de a RLS ser avaliada.
