-- DV-04 - Reviews Module
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Modelo de avaliacao por restaurante (DV-04 SS9), nao por evento - decisao
-- explicita que ignora o modelo do ET-08 (baseado em event_id). Nao existe
-- modulo DV de "Eventos" no roadmap atual.

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete restrict,
  rating numeric(2, 1) not null check (rating >= 1 and rating <= 5),
  comment text,
  likes_count integer not null default 0 check (likes_count >= 0),
  photos_count integer not null default 0 check (photos_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint reviews_user_restaurant_unique unique (user_id, restaurant_id)
);

create index reviews_restaurant_id_idx on public.reviews (restaurant_id);
create index reviews_user_id_idx on public.reviews (user_id);

alter table public.reviews enable row level security;

-- SELECT: qualquer usuario autenticado (DV-04).
create policy "reviews_select_authenticated"
  on public.reviews for select
  to authenticated
  using (true);

-- INSERT: somente o proprio usuario, como autor da avaliacao.
create policy "reviews_insert_own"
  on public.reviews for insert
  to authenticated
  with check (auth.uid() = user_id);

-- UPDATE: somente o proprio autor. A exclusao logica (deleted_at) tambem
-- passa por esta policy, pois e uma atualizacao da propria linha.
create policy "reviews_update_own"
  on public.reviews for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- DELETE fisico: nao implementado nesta etapa (decisao do DV-04 - somente
-- exclusao logica via deleted_at).

-- Reutiliza a funcao compartilhada criada em
-- 20260718212615_add_set_updated_at_function.sql - nao recriar por tabela.
create trigger set_reviews_updated_at
  before update on public.reviews
  for each row execute procedure public.set_updated_at();
