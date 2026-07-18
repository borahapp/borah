-- DV-03 - Restaurants Module
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- `status` e `deleted_at` existem apenas como preparacao para evolucao
-- futura (moderacao no DV-08, soft delete alinhado ao RN-003 do ET-07) -
-- nenhuma logica de moderacao ou exclusao logica e implementada agora.

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  description text,
  address text,
  city text,
  state text,
  latitude numeric,
  longitude numeric,
  average_rating numeric,
  total_reviews integer not null default 0,
  cover_image text,
  status text not null default 'active',
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.restaurants enable row level security;

-- SELECT: qualquer usuario autenticado (DV-03).
create policy "restaurants_select_authenticated"
  on public.restaurants for select
  to authenticated
  using (true);

-- INSERT: qualquer usuario autenticado pode cadastrar (DV-03 - decisao
-- de modelo colaborativo, sem moderacao nesta etapa).
create policy "restaurants_insert_authenticated"
  on public.restaurants for insert
  to authenticated
  with check (auth.uid() = created_by);

-- UPDATE: somente quem cadastrou (DV-03). Edicao por administradores
-- fica para quando o DV-08 definir papeis.
create policy "restaurants_update_own"
  on public.restaurants for update
  to authenticated
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);

-- DELETE: nao implementado nesta etapa (decisao do DV-03).

-- Reutiliza a funcao compartilhada criada em
-- 20260718212615_add_set_updated_at_function.sql - nao recriar por tabela.
create trigger set_restaurants_updated_at
  before update on public.restaurants
  for each row execute procedure public.set_updated_at();
