-- DV-09 - Notifications Module
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Somente In-App nesta versao - sem Push (sem Provider configurado) e sem
-- Edge Functions (geracao via trigger - ver 20260720100030). `payload`
-- guarda apenas identificadores para navegacao futura, nunca conteudo
-- duplicado (decisao do DV-09).

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (type in ('new_follower', 'new_comment', 'new_like')),
  title text not null,
  message text not null,
  payload jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index notifications_user_id_idx on public.notifications (user_id);

alter table public.notifications enable row level security;

-- SELECT/UPDATE (marcar como lida): somente o proprio destinatario.
create policy "notifications_select_own"
  on public.notifications for select
  to authenticated
  using (auth.uid() = user_id);

create policy "notifications_update_own"
  on public.notifications for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- INSERT: NAO implementado para o cliente (decisao 4 do DV-09) - somente
-- os triggers (SECURITY DEFINER, ver 20260720100030) escrevem aqui.
-- DELETE: nao implementado.
