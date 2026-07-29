-- DV-08 - Administration Module (RBAC)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Papeis administrativos (DV-08 SS3): super_admin, admin, moderator,
-- support. UNIQUE(user_id) - um usuario tem no maximo um papel
-- administrativo (tratado como "perfil" no singular pelo proprio DV-08).
--
-- BOOTSTRAP: a policy de INSERT abaixo exige que quem concede um papel ja
-- seja super_admin - isso e intencional (impede auto-promocao), mas
-- significa que o PRIMEIRO super_admin precisa ser inserido manualmente
-- via SQL direto (Supabase SQL editor ou script com privilegios
-- elevados, fora do RLS), nao pelo app. Nao ha mecanismo de bootstrap
-- automatico nesta versao.

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('super_admin', 'admin', 'moderator', 'support')),
  created_at timestamptz not null default now(),

  constraint user_roles_user_unique unique (user_id)
);

create function public.is_admin(uid uuid)
returns boolean
language sql
stable
as $$
  select exists (select 1 from public.user_roles where user_id = uid);
$$;

create function public.has_admin_role(uid uuid, required_role text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.user_roles where user_id = uid and role = required_role
  );
$$;

-- Papeis com capacidade de moderar conteudo (RN "menor privilegio" -
-- support e apenas consulta, nao modera).
create function public.can_moderate(uid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = uid and role in ('super_admin', 'admin', 'moderator')
  );
$$;

alter table public.user_roles enable row level security;

-- SELECT: qualquer administrador ve a lista de papeis (tela de Papeis).
create policy "user_roles_select_admin"
  on public.user_roles for select
  to authenticated
  using (public.is_admin(auth.uid()));

-- INSERT/UPDATE/DELETE: somente super_admin gerencia papeis de outros
-- administradores (decisao do DV-08 - "Alterar permissoes").
create policy "user_roles_insert_super_admin"
  on public.user_roles for insert
  to authenticated
  with check (public.has_admin_role(auth.uid(), 'super_admin'));

create policy "user_roles_update_super_admin"
  on public.user_roles for update
  to authenticated
  using (public.has_admin_role(auth.uid(), 'super_admin'))
  with check (public.has_admin_role(auth.uid(), 'super_admin'));

create policy "user_roles_delete_super_admin"
  on public.user_roles for delete
  to authenticated
  using (public.has_admin_role(auth.uid(), 'super_admin'));
