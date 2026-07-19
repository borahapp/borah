-- DV-10 - Gamification Module (conquistas do usuario)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- UNIQUE(user_id, badge_id) - um badge e concedido no maximo uma vez (RN
-- do DV-10). ON DELETE RESTRICT em badge_id: o catalogo e fixo, nao deve
-- ser removido enquanto houver conquistas associadas.

create table public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  badge_id uuid not null references public.badges (id) on delete restrict,
  earned_at timestamptz not null default now(),

  constraint user_badges_unique unique (user_id, badge_id)
);

alter table public.user_badges enable row level security;

create policy "user_badges_select_authenticated"
  on public.user_badges for select
  to authenticated
  using (true);

-- INSERT: nao implementado para o cliente - somente a funcao
-- award_badge() (SECURITY DEFINER) concede badges.
