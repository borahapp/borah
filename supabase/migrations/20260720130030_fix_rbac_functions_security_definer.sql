-- Correção operacional - Bug 3 da Validação Funcional do Backend (2026-07-20)
--
-- `is_admin()`, `has_admin_role()` e `can_moderate()` (criadas em
-- 20260719160000_create_user_roles.sql) não eram SECURITY DEFINER. Elas
-- consultam `user_roles`, cuja própria policy de SELECT
-- (`user_roles_select_admin`) exige `is_admin(auth.uid())` para
-- qualquer linha ser visível - inclusive a própria linha do usuário
-- consultado. Sem SECURITY DEFINER, a consulta interna reavalia essa
-- mesma policy, que chama a mesma função de novo - recursão infinita.
--
-- Confirmado empiricamente com `ERROR: 54001: stack depth limit
-- exceeded`: assim que o primeiro super_admin é criado, ele mesmo não
-- consegue mais verificar sua própria permissão através de nenhuma
-- policy que dependa dessas três funções (`user_roles`, `restaurants`,
-- `reviews`, `comments`, `comment_reports`, `audit_logs`) - o módulo de
-- Administração inteiro (DV-08) ficava inoperante.
--
-- Corrigido com o mesmo padrão do fix do Bug 2: SECURITY DEFINER faz a
-- consulta interna a `user_roles` rodar sem RLS, quebrando a
-- recursão - é também o padrão oficialmente documentado pelo Supabase
-- para funções auxiliares de checagem de papel usadas dentro de
-- policies.
--
-- Apenas `CREATE OR REPLACE FUNCTION` - corpo idêntico ao original, só
-- adiciona `security definer set search_path`. Nenhuma policy precisa
-- ser alterada.

create or replace function public.is_admin(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.user_roles where user_id = uid);
$$;

create or replace function public.has_admin_role(uid uuid, required_role text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.user_roles where user_id = uid and role = required_role
  );
$$;

create or replace function public.can_moderate(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = uid and role in ('super_admin', 'admin', 'moderator')
  );
$$;
