-- DV-09 - Notifications Module (preferencias)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- 5 categorias por estrutura (DV-09 SS11), mas apenas 'social' tem algum
-- evento real implementado nesta versao - as demais existem só como
-- estrutura de banco, sem UI (decisao 5 do DV-09). Ausencia de linha =
-- notificacoes habilitadas por padrao (modelo opt-out).

create table public.notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null check (
    category in ('social', 'restaurants', 'reviews', 'system', 'gamification')
  ),
  in_app_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint notification_preferences_unique unique (user_id, category)
);

alter table public.notification_preferences enable row level security;

create policy "notification_preferences_select_own"
  on public.notification_preferences for select
  to authenticated
  using (auth.uid() = user_id);

create policy "notification_preferences_insert_own"
  on public.notification_preferences for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "notification_preferences_update_own"
  on public.notification_preferences for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Reutiliza a funcao compartilhada criada em
-- 20260718212615_add_set_updated_at_function.sql - nao recriar por tabela.
create trigger set_notification_preferences_updated_at
  before update on public.notification_preferences
  for each row execute procedure public.set_updated_at();
