-- DV-10 - Gamification Module (catalogo de badges)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Catalogo fixo, semeado nesta propria migracao - sem escrita do cliente.
-- Criterios de desbloqueio (decisao do DV-10):
-- - first_review: primeira avaliacao publicada.
-- - explorador: 10 restaurantes diferentes avaliados.
-- - gourmet: 500 XP acumulados.
-- - influenciador: 50 curtidas recebidas nas avaliacoes.
-- - critico: 25 avaliacoes publicadas.

create table public.badges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text
);

alter table public.badges enable row level security;

create policy "badges_select_authenticated"
  on public.badges for select
  to authenticated
  using (true);

-- INSERT/UPDATE/DELETE: nao implementado para o cliente.

insert into public.badges (code, name, description) values
  ('first_review', 'Primeira Avaliação', 'Publicou sua primeira avaliação.'),
  ('explorador', 'Explorador', 'Avaliou 10 restaurantes diferentes.'),
  ('gourmet', 'Gourmet', 'Acumulou 500 XP.'),
  ('influenciador', 'Influenciador', 'Recebeu 50 curtidas em suas avaliações.'),
  ('critico', 'Crítico', 'Publicou 25 avaliações.');
