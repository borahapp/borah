-- DV-10 - Gamification Module
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Sem linha ate o primeiro evento de gamificacao do usuario - criada via
-- upsert na funcao award_gamification_points (20260720120100), nao por um
-- trigger de cadastro. SELECT publica (necessaria para o Ranking de
-- Usuarios); escrita somente via funcoes SECURITY DEFINER.

create table public.user_progress (
  user_id uuid primary key references auth.users (id) on delete cascade,
  xp integer not null default 0,
  points integer not null default 0,
  level integer not null default 1,
  updated_at timestamptz not null default now()
);

alter table public.user_progress enable row level security;

create policy "user_progress_select_authenticated"
  on public.user_progress for select
  to authenticated
  using (true);

-- INSERT/UPDATE: nao implementado para o cliente - somente as funcoes
-- SECURITY DEFINER (triggers de gamificacao) escrevem aqui.
