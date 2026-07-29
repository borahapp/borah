-- DV-02 - Users Module
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B). A trigger sobre auth.users
-- em especifico nao foi testada em execucao.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  bio text,
  avatar_url text,
  city text,
  state text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- SELECT: qualquer usuario autenticado (DV-02 - "Visualizacao de Perfil").
-- Perfil publico/privado fica para a Evolucao prevista v2.0 do DV-02.
create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

-- INSERT: somente o proprio usuario (defesa em profundidade - a criacao
-- normal ocorre via trigger abaixo, com security definer).
create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

-- UPDATE: somente o proprio usuario (DV-02 SS3).
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- DELETE: nao implementado nesta etapa (decisao do DV-02).

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
