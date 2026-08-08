-- FASE C.2.3 - Suíte de validação das permissões administrativas
-- (escrita e revisada estaticamente; execução pendente)
--
-- STATUS: esta suíte foi escrita e revisada estaticamente, e está
-- pronta para execução - mas a validação EFETIVA contra uma instância
-- real (Postgres/Supabase) ainda não aconteceu. Docker Desktop foi
-- iniciado nesta sessão, mas o daemon não respondeu dentro do tempo
-- disponível, então nenhuma asserção abaixo foi de fato executada.
-- Nenhuma conclusão de segurança deste arquivo deve ser tratada como
-- confirmada até que alguém rode, com Docker/Supabase funcionando:
-- `supabase start`, depois `supabase test db --local
-- supabase/tests/database`. Mesma ressalva já registrada nos demais
-- arquivos deste diretório.
--
-- Objetivo (distinto de 10_/30_): checar, num único lugar e mapeado
-- 1:1 às 4 áreas do painel administrativo (Restaurants Administration,
-- Roles Administration, Moderation, Audit Log), que um usuário SEM
-- NENHUM papel administrativo (não é `support`, não é nada) é negado em
-- cada uma das 5 operações citadas no pedido de validação, e que um
-- administrador com o papel mínimo necessário consegue executar todas
-- elas normalmente. `10_rls_private_tables.test.sql` já cobre
-- visibilidade de `user_roles`/`audit_logs` para usuário comum; `30_` já
-- cobre a hierarquia entre papéis administrativos (ex.: admin vs
-- super_admin, moderator vs support) - este arquivo fecha as lacunas
-- que sobraram: UPDATE/DELETE em `user_roles` por usuário comum (só
-- INSERT estava coberto), moderação de `reviews` (não coberta em
-- nenhum arquivo, nem o caminho positivo nem o negativo), e moderação
-- de `restaurants`/`comments` especificamente contra um usuário SEM
-- papel algum (só `support` era usado como caso negativo em `30_`).
--
-- Também busca responder uma pergunta que nenhum arquivo anterior
-- verificou: `is_admin()`/`has_admin_role()`/`can_moderate()` são
-- `SECURITY DEFINER` sem `revoke execute from public` explícito
-- (diferente das RPCs voltadas ao cliente, como
-- `transfer_group_ownership`) - ao contrário de tabelas, o privilégio
-- EXECUTE em funções é concedido a PUBLIC por padrão no Postgres puro.
-- `supabase/config.toml` (`auto_expose_new_tables`, comentado/ausente =
-- "novas entidades NÃO são auto-expostas, padrão atual da nuvem")
-- sugere que a plataforma Supabase revoga isso automaticamente também
-- para funções, mas isso permanece NÃO CONFIRMADO - é a pergunta de
-- maior prioridade para responder assim que este arquivo puder ser
-- executado. Se alguma dessas 3 funções estiver de fato alcançável via
-- RPC por `anon`/`authenticated`, qualquer usuário poderia perguntar
-- diretamente "este user_id é admin?"/"qual o papel dele?",
-- contornando a RLS de `user_roles` por um canal lateral. As asserções
-- abaixo estão preparadas para responder isso de forma definitiva
-- quando executadas - não antes.
--
-- Toda a suíte roda dentro de uma transação revertida ao final.

begin;

select plan(18);

-- ---------------------------------------------------------------------
-- Fixtures (como `postgres`, bypassa RLS)
-- ---------------------------------------------------------------------

set local role postgres;

insert into auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('c2000000-0000-0000-0000-000000000001', 'regular@rls-c223.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('c2000000-0000-0000-0000-000000000002', 'content-owner@rls-c223.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('c2000000-0000-0000-0000-000000000003', 'moderator@rls-c223.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('c2000000-0000-0000-0000-000000000004', 'super-admin@rls-c223.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('c2000000-0000-0000-0000-000000000005', 'target-user@rls-c223.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.user_roles (user_id, role) values
  ('c2000000-0000-0000-0000-000000000003', 'moderator'),
  ('c2000000-0000-0000-0000-000000000004', 'super_admin')
on conflict (user_id) do nothing;

insert into public.restaurants (id, name, category, created_by)
values ('c2000000-0000-0000-0000-000000000010', 'Restaurante de Terceiro', 'test', 'c2000000-0000-0000-0000-000000000002')
on conflict (id) do nothing;

insert into public.reviews (id, restaurant_id, user_id, rating, comment)
values ('c2000000-0000-0000-0000-000000000011', 'c2000000-0000-0000-0000-000000000010', 'c2000000-0000-0000-0000-000000000002', 4, 'avaliação de terceiro')
on conflict (id) do nothing;

insert into public.comments (id, review_id, user_id, content)
values ('c2000000-0000-0000-0000-000000000012', 'c2000000-0000-0000-0000-000000000011', 'c2000000-0000-0000-0000-000000000002', 'comentário de terceiro')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Usuário comum (SEM nenhum papel administrativo) - as 5 operações
-- citadas no pedido de validação devem ser todas negadas.
-- ---------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims to '{"sub":"c2000000-0000-0000-0000-000000000001","role":"authenticated"}';

-- 1. Promover usuário (Roles Administration - INSERT)
select throws_ok(
  $$ insert into public.user_roles (user_id, role) values ('c2000000-0000-0000-0000-000000000005', 'moderator') $$,
  '42501',
  'usuário comum: NÃO pode promover outro usuário a administrador (user_roles INSERT)'
);

-- 2. Remover papel (Roles Administration - UPDATE do papel de um admin
-- já existente, e DELETE/revogação)
select is(
  (with updated as (
    update public.user_roles set role = 'admin'
    where user_id = 'c2000000-0000-0000-0000-000000000003'
    returning user_id
  ) select count(*) from updated),
  0::bigint,
  'usuário comum: NÃO pode alterar o papel de um administrador (user_roles UPDATE)'
);

select is(
  (with deleted as (
    delete from public.user_roles where user_id = 'c2000000-0000-0000-0000-000000000003' returning user_id
  ) select count(*) from deleted),
  0::bigint,
  'usuário comum: NÃO pode revogar o papel de um administrador (user_roles DELETE)'
);

-- 3. Alterar restaurante (Restaurants Administration - moderação de
-- restaurante de terceiro via can_moderate())
select is(
  (with updated as (
    update public.restaurants set status = 'archived'
    where id = 'c2000000-0000-0000-0000-000000000010'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'usuário comum: NÃO pode arquivar/alterar restaurante de outro usuário (restaurants UPDATE)'
);

-- 4. Moderar conteúdo - comentário de terceiro (Moderation)
select is(
  (with updated as (
    update public.comments set deleted_at = now()
    where id = 'c2000000-0000-0000-0000-000000000012'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'usuário comum: NÃO pode ocultar comentário de outro usuário (comments UPDATE)'
);

-- 5. Moderar conteúdo - avaliação de terceiro (Moderation) - nenhum
-- arquivo anterior cobria `reviews_update_admin`.
select is(
  (with updated as (
    update public.reviews set deleted_at = now()
    where id = 'c2000000-0000-0000-0000-000000000011'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'usuário comum: NÃO pode ocultar avaliação de outro usuário (reviews UPDATE)'
);

-- 6. Consultar audit log (Audit Log)
select is(
  (select count(*) from public.audit_logs),
  0::bigint,
  'usuário comum: NÃO enxerga nenhuma linha do audit log (audit_logs SELECT)'
);

-- ---------------------------------------------------------------------
-- Administrador - cada operação acima deve funcionar normalmente com o
-- papel mínimo necessário (super_admin para Roles Administration,
-- moderator para Restaurants/Moderation, qualquer papel para Audit Log).
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"c2000000-0000-0000-0000-000000000004","role":"authenticated"}';

select is(
  (with inserted as (
    insert into public.user_roles (user_id, role) values ('c2000000-0000-0000-0000-000000000005', 'support')
    returning user_id
  ) select count(*) from inserted),
  1::bigint,
  'super_admin: consegue promover outro usuário (user_roles INSERT)'
);

select is(
  (with updated as (
    update public.user_roles set role = 'moderator'
    where user_id = 'c2000000-0000-0000-0000-000000000005'
    returning user_id
  ) select count(*) from updated),
  1::bigint,
  'super_admin: consegue alterar o papel de outro administrador (user_roles UPDATE)'
);

select is(
  (with deleted as (
    delete from public.user_roles where user_id = 'c2000000-0000-0000-0000-000000000005' returning user_id
  ) select count(*) from deleted),
  1::bigint,
  'super_admin: consegue revogar o papel de outro administrador (user_roles DELETE)'
);

set local request.jwt.claims to '{"sub":"c2000000-0000-0000-0000-000000000003","role":"authenticated"}';

select is(
  (with updated as (
    update public.restaurants set status = 'archived'
    where id = 'c2000000-0000-0000-0000-000000000010'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'moderator: consegue arquivar/alterar restaurante de outro usuário (restaurants UPDATE)'
);

select is(
  (with updated as (
    update public.comments set deleted_at = now()
    where id = 'c2000000-0000-0000-0000-000000000012'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'moderator: consegue ocultar comentário de outro usuário (comments UPDATE)'
);

select is(
  (with updated as (
    update public.reviews set deleted_at = now()
    where id = 'c2000000-0000-0000-0000-000000000011'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'moderator: consegue ocultar avaliação de outro usuário (reviews UPDATE)'
);

select ok(
  (select count(*) from public.audit_logs) >= 0,
  'moderator: consegue consultar o audit log sem erro (audit_logs SELECT)'
);

-- ---------------------------------------------------------------------
-- Privilégio EXECUTE das funções auxiliares de RBAC - diferente de
-- tabelas, o Postgres concede EXECUTE a PUBLIC por padrão na criação de
-- uma função; nenhuma das 3 tem `revoke execute from public` explícito
-- (só as RPCs voltadas ao cliente, como create_group/
-- transfer_group_ownership, têm essa revogação). Se `anon`/
-- `authenticated` conseguirem chamá-las diretamente via RPC, um usuário
-- não autenticado ou comum poderia perguntar "este user_id é admin?"
-- por um canal que não passa pela RLS de `user_roles`.
-- ---------------------------------------------------------------------

set local role postgres;

select ok(
  not has_function_privilege('anon', 'public.is_admin(uuid)', 'EXECUTE'),
  'is_admin(): anon NÃO deveria ter privilégio EXECUTE'
);

select ok(
  not has_function_privilege('authenticated', 'public.is_admin(uuid)', 'EXECUTE'),
  'is_admin(): authenticated NÃO deveria ter privilégio EXECUTE (só é usada dentro de policies)'
);

select ok(
  not has_function_privilege('authenticated', 'public.has_admin_role(uuid, text)', 'EXECUTE'),
  'has_admin_role(): authenticated NÃO deveria ter privilégio EXECUTE (só é usada dentro de policies)'
);

select ok(
  not has_function_privilege('authenticated', 'public.can_moderate(uuid)', 'EXECUTE'),
  'can_moderate(): authenticated NÃO deveria ter privilégio EXECUTE (só é usada dentro de policies)'
);

select * from finish();

rollback;
