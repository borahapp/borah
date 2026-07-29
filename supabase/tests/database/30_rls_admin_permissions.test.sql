-- RC-04A - Security Hardening
-- Suíte de RLS: permissões administrativas (user_roles, feature_flags,
-- audit_logs, moderação de conteúdo via can_moderate).
--
-- COMO RODAR: `supabase start` (requer Docker), depois
-- `supabase test db --local supabase/tests/database`. Este arquivo NÃO
-- foi executado nem validado contra uma instância real - ver a mesma
-- ressalva em `10_rls_private_tables.test.sql`.
--
-- Hierarquia testada (DV-08): super_admin > admin > moderator > support.
-- `is_admin()` é verdadeiro para QUALQUER um dos 4 papéis (usado para
-- SELECT de user_roles/audit_logs e leitura administrativa em geral).
-- `has_admin_role(uid, 'super_admin')` exige exatamente esse papel
-- (usado para escrever em user_roles/feature_flags). `can_moderate()` é
-- verdadeiro para super_admin/admin/moderator, mas FALSO para support
-- (usado para moderar restaurants/reviews/comments de outros usuários).
--
-- Para os testes de "não pode escrever", uso `admin` (não super_admin)
-- como representante do caso negativo em `user_roles`/`feature_flags` -
-- a condição da policy (`has_admin_role(uid,'super_admin')`) é uma
-- igualdade exata de papel, não uma hierarquia numérica, então testar
-- com `moderator`/`support` adicionaria cobertura redundante (mesma
-- expressão booleana, resultado idêntico) sem valor extra.
--
-- Toda a suíte roda dentro de uma transação revertida ao final.

begin;

select plan(26);

-- ---------------------------------------------------------------------
-- Fixtures (como `postgres`, bypassa RLS)
-- ---------------------------------------------------------------------

set local role postgres;

insert into auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('10000000-0000-0000-0000-000000000001', 'regular@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('30000000-0000-0000-0000-000000000001', 'super-admin@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('40000000-0000-0000-0000-000000000001', 'admin@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('50000000-0000-0000-0000-000000000001', 'moderator@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('60000000-0000-0000-0000-000000000001', 'support@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.user_roles (user_id, role) values
  ('30000000-0000-0000-0000-000000000001', 'super_admin'),
  ('40000000-0000-0000-0000-000000000001', 'admin'),
  ('50000000-0000-0000-0000-000000000001', 'moderator'),
  ('60000000-0000-0000-0000-000000000001', 'support')
on conflict (user_id) do nothing;

insert into public.feature_flags (id, key, enabled, description)
values ('70000000-0000-0000-0000-000000000001', 'rls_test_flag', false, 'flag de teste da suíte RLS')
on conflict (id) do nothing;

insert into public.audit_logs (id, actor_id, action, entity, entity_id)
values ('80000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'grant_admin_role', 'user', '40000000-0000-0000-0000-000000000001')
on conflict (id) do nothing;

insert into public.restaurants (id, name, category, created_by)
values ('90000000-0000-0000-0000-000000000001', 'Restaurante do Usuário Comum', 'test', '10000000-0000-0000-0000-000000000001')
on conflict (id) do nothing;

insert into public.reviews (id, restaurant_id, user_id, rating, comment)
values ('a0000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 5, 'ótimo')
on conflict (id) do nothing;

insert into public.comments (id, review_id, user_id, content)
values ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'comentário do usuário comum')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- user_roles: SELECT é permitido a qualquer papel administrativo
-- (inclusive support, que só consulta) - decisão documentada do DV-08
-- ("tela de Papéis" lista todos os administradores para gestão).
-- ---------------------------------------------------------------------

set local role authenticated;

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001","role":"authenticated"}';
select is((select count(*) from public.user_roles), 4::bigint, 'user_roles: super_admin vê os 4 papéis (SELECT)');

set local request.jwt.claims to '{"sub":"40000000-0000-0000-0000-000000000001","role":"authenticated"}';
select is((select count(*) from public.user_roles), 4::bigint, 'user_roles: admin vê os 4 papéis (SELECT)');

set local request.jwt.claims to '{"sub":"50000000-0000-0000-0000-000000000001","role":"authenticated"}';
select is((select count(*) from public.user_roles), 4::bigint, 'user_roles: moderator vê os 4 papéis (SELECT)');

set local request.jwt.claims to '{"sub":"60000000-0000-0000-0000-000000000001","role":"authenticated"}';
select is((select count(*) from public.user_roles), 4::bigint, 'user_roles: support vê os 4 papéis (SELECT) - decisão documentada do DV-08');

-- ---------------------------------------------------------------------
-- user_roles: escrita exige exatamente super_admin - `admin` (papel
-- imediatamente abaixo) representa o caso negativo.
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"40000000-0000-0000-0000-000000000001","role":"authenticated"}';

select throws_ok(
  $$ insert into public.user_roles (user_id, role) values ('10000000-0000-0000-0000-000000000001', 'support') $$,
  '42501',
  'user_roles: admin (não-super_admin) não pode conceder papel (INSERT)'
);

select is(
  (with updated as (
    update public.user_roles set role = 'admin'
    where user_id = '50000000-0000-0000-0000-000000000001'
    returning user_id
  ) select count(*) from updated),
  0::bigint,
  'user_roles: admin (não-super_admin) não pode alterar papel de outro admin (UPDATE)'
);

select is(
  (with deleted as (
    delete from public.user_roles where user_id = '60000000-0000-0000-0000-000000000001' returning user_id
  ) select count(*) from deleted),
  0::bigint,
  'user_roles: admin (não-super_admin) não pode revogar papel de outro admin (DELETE)'
);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is(
  (with inserted as (
    insert into public.user_roles (user_id, role) values ('10000000-0000-0000-0000-000000000001', 'support')
    returning user_id
  ) select count(*) from inserted),
  1::bigint,
  'user_roles: super_admin pode conceder um papel novo (INSERT)'
);

select is(
  (with updated as (
    update public.user_roles set role = 'admin'
    where user_id = '50000000-0000-0000-0000-000000000001'
    returning user_id
  ) select count(*) from updated),
  1::bigint,
  'user_roles: super_admin pode alterar o papel de outro admin (UPDATE)'
);

select is(
  (with deleted as (
    delete from public.user_roles where user_id = '10000000-0000-0000-0000-000000000001' returning user_id
  ) select count(*) from deleted),
  1::bigint,
  'user_roles: super_admin pode revogar um papel (DELETE)'
);

-- ---------------------------------------------------------------------
-- feature_flags: SELECT é público a qualquer autenticado; escrita
-- exige exatamente super_admin (RC-03D).
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is(
  (select count(*) from public.feature_flags where id = '70000000-0000-0000-0000-000000000001'),
  1::bigint,
  'feature_flags: usuário comum consegue ler as flags (SELECT)'
);

set local request.jwt.claims to '{"sub":"40000000-0000-0000-0000-000000000001","role":"authenticated"}';

select throws_ok(
  $$ insert into public.feature_flags (key, enabled) values ('outra_flag', false) $$,
  '42501',
  'feature_flags: admin (não-super_admin) não pode criar flag (INSERT)'
);

select is(
  (with updated as (
    update public.feature_flags set enabled = true
    where id = '70000000-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'feature_flags: admin (não-super_admin) não pode alterar flag (UPDATE)'
);

select is(
  (with deleted as (
    delete from public.feature_flags where id = '70000000-0000-0000-0000-000000000001' returning id
  ) select count(*) from deleted),
  0::bigint,
  'feature_flags: admin (não-super_admin) não pode remover flag (DELETE)'
);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is(
  (with inserted as (
    insert into public.feature_flags (key, enabled) values ('outra_flag', false)
    returning id
  ) select count(*) from inserted),
  1::bigint,
  'feature_flags: super_admin pode criar flag (INSERT)'
);

select is(
  (with updated as (
    update public.feature_flags set enabled = true
    where id = '70000000-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'feature_flags: super_admin pode alterar flag (UPDATE)'
);

select is(
  (with deleted as (
    delete from public.feature_flags where id = '70000000-0000-0000-0000-000000000001' returning id
  ) select count(*) from deleted),
  1::bigint,
  'feature_flags: super_admin pode remover flag (DELETE)'
);

-- ---------------------------------------------------------------------
-- audit_logs: qualquer admin (inclusive support) lê e registra a
-- PRÓPRIA ação; ninguém, nem super_admin, pode alterar/apagar
-- (append-only por design do DV-08).
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"60000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is(
  (select count(*) from public.audit_logs where id = '80000000-0000-0000-0000-000000000001'),
  1::bigint,
  'audit_logs: support consegue ler o histórico de auditoria (SELECT)'
);

select is(
  (with inserted as (
    insert into public.audit_logs (actor_id, action, entity, entity_id)
    values ('60000000-0000-0000-0000-000000000001', 'view_report', 'comment_report', 'b0000000-0000-0000-0000-000000000001')
    returning id
  ) select count(*) from inserted),
  1::bigint,
  'audit_logs: support pode registrar a própria ação (INSERT)'
);

select throws_ok(
  $$ insert into public.audit_logs (actor_id, action, entity, entity_id) values ('40000000-0000-0000-0000-000000000001', 'x', 'x', '10000000-0000-0000-0000-000000000001') $$,
  '42501',
  'audit_logs: support não pode registrar uma ação em nome de outro admin (INSERT, impersonation)'
);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001","role":"authenticated"}';

select throws_ok(
  $$ update public.audit_logs set action = 'hack' where id = '80000000-0000-0000-0000-000000000001' $$,
  '42501',
  'audit_logs: nem super_admin pode alterar um registro (UPDATE - append-only, sem GRANT)'
);

select throws_ok(
  $$ delete from public.audit_logs where id = '80000000-0000-0000-0000-000000000001' $$,
  '42501',
  'audit_logs: nem super_admin pode apagar um registro (DELETE - append-only, sem GRANT)'
);

-- ---------------------------------------------------------------------
-- can_moderate: moderator (e admin/super_admin, por extensão da mesma
-- condição) pode moderar conteúdo de QUALQUER usuário; support não,
-- mesmo sendo administrador (RN "menor privilégio" do DV-08).
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"50000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is(
  (with updated as (
    update public.restaurants set status = 'archived'
    where id = '90000000-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'restaurants: moderator pode arquivar o restaurante de outro usuário (UPDATE)'
);

-- Só altera `deleted_at`, nunca `content` - não deve disparar o
-- trigger de janela de edição de 15 minutos (esse só reage a mudança
-- de `content`, ver enforce_comment_edit_window_trigger, DV-07).
select is(
  (with updated as (
    update public.comments set deleted_at = now()
    where id = 'b0000000-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'comments: moderator pode ocultar (soft delete) o comentário de outro usuário (UPDATE)'
);

set local request.jwt.claims to '{"sub":"60000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is(
  (with updated as (
    update public.restaurants set status = 'archived'
    where id = '90000000-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'restaurants: support NÃO pode moderar (UPDATE) - can_moderate() exclui support por design'
);

select is(
  (with updated as (
    update public.comments set deleted_at = now()
    where id = 'b0000000-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'comments: support NÃO pode moderar (UPDATE) - can_moderate() exclui support por design'
);

select * from finish();

rollback;
