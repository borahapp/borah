-- DV-06 - Favorites Module
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- ON DELETE CASCADE em ambas as FKs (diferente do RESTRICT usado em
-- reviews.restaurant_id/user_id): um favorito e um bookmark pessoal sem
-- valor proprio - se o restaurante ou o usuario deixar de existir, o
-- favorito deve desaparecer junto (mesmo raciocinio do review_likes do
-- DV-04, nao o de reviews).

create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  created_at timestamptz not null default now(),

  constraint favorites_user_restaurant_unique unique (user_id, restaurant_id)
);

alter table public.favorites enable row level security;

-- Favoritos sao privados por usuario (DV-06 RN "favoritos pertencem
-- exclusivamente ao usuario") - diferente de restaurants/reviews, que sao
-- publicos para qualquer autenticado.

-- SELECT: somente o proprio usuario.
create policy "favorites_select_own"
  on public.favorites for select
  to authenticated
  using (auth.uid() = user_id);

-- INSERT: somente o proprio usuario.
create policy "favorites_insert_own"
  on public.favorites for insert
  to authenticated
  with check (auth.uid() = user_id);

-- DELETE: somente o proprio usuario.
create policy "favorites_delete_own"
  on public.favorites for delete
  to authenticated
  using (auth.uid() = user_id);

-- UPDATE: nao implementado (decisao do DV-06 - favoritar/desfavoritar e
-- sempre insert/delete, nunca update).
