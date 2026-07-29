-- DV-07 - Social Module (seguidores)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).

create table public.followers (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references auth.users (id) on delete cascade,
  following_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),

  constraint followers_unique unique (follower_id, following_id),
  constraint followers_no_self_follow check (follower_id <> following_id)
);

alter table public.followers enable row level security;

-- SELECT: aberta a autenticados - nao existe coluna de privacidade em
-- profiles (lacuna ja registrada no DV-02), entao seguidores/seguindo
-- sao publicos, como restaurants/reviews.
create policy "followers_select_authenticated"
  on public.followers for select
  to authenticated
  using (true);

-- INSERT/DELETE: somente o proprio seguidor (seguir/deixar de seguir).
create policy "followers_insert_own"
  on public.followers for insert
  to authenticated
  with check (auth.uid() = follower_id);

create policy "followers_delete_own"
  on public.followers for delete
  to authenticated
  using (auth.uid() = follower_id);

-- UPDATE: nao implementado (seguir/deixar de seguir e sempre insert/delete).
