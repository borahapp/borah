-- RC-04A - Security Hardening
-- Suíte de RLS: tabelas privadas (dado pertence exclusivamente ao dono).
--
-- COMO RODAR: `supabase start` (requer Docker), depois
-- `supabase test db --local supabase/tests/database`. Este arquivo NÃO
-- foi executado nem validado contra uma instância real - foi escrito e
-- revisado estaticamente, seguindo o padrão pgTAP oficial do Supabase
-- (mesma ressalva já aplicada a toda migration deste projeto, ver
-- AR-06/EX-01B). Rode localmente antes de confiar no resultado.
--
-- Convenção: os testes de INSERT indevido usam `throws_ok(..., '42501')`
-- (violação de RLS/GRANT sempre lança `insufficient_privilege`). Os
-- testes de SELECT/UPDATE/DELETE indevidos usam contagem de linhas
-- (0 linhas) - a cláusula USING de uma policy nega tornando a linha
-- invisível, sem lançar exceção, então a asserção correta é "0 linhas
-- afetadas/retornadas", não "lança erro".
--
-- Toda a suíte roda dentro de uma transação revertida ao final -
-- nenhum dado de teste persiste no banco.

begin;

select plan(24);

-- ---------------------------------------------------------------------
-- Fixtures (como `postgres`, bypassa RLS)
-- ---------------------------------------------------------------------

set local role postgres;

insert into auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('11111111-1111-1111-1111-111111111111', 'user-a@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 'user-b@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.restaurants (id, name, category, created_by)
values ('aaaaaaaa-0000-0000-0000-000000000001', 'Restaurante RLS Test', 'test', '11111111-1111-1111-1111-111111111111')
on conflict (id) do nothing;

insert into public.reviews (id, restaurant_id, user_id, rating, comment)
values ('bbbbbbbb-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 5, 'ótimo')
on conflict (id) do nothing;

insert into public.comments (id, review_id, user_id, content)
values ('cccccccc-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'comentário de A')
on conflict (id) do nothing;

-- Dado privado pertencente a A, em cada tabela sob teste.
insert into public.favorites (id, user_id, restaurant_id)
values ('dddddddd-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001')
on conflict (id) do nothing;

insert into public.notifications (id, user_id, type, title, message)
values ('eeeeeeee-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'new_follower', 'Novo seguidor', 'Alguém começou a seguir você.')
on conflict (id) do nothing;

insert into public.notification_preferences (id, user_id, category, in_app_enabled)
values ('ffffffff-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'social', true)
on conflict (id) do nothing;

insert into public.comment_reports (id, comment_id, reported_by, reason)
values ('11111111-0000-0000-0000-000000000001', 'cccccccc-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'spam')
on conflict (id) do nothing;

insert into public.feedback (id, user_id, message, status)
values ('22222222-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'feedback de A', 'new')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- favorites: A é dono; B nunca deve ler/escrever/apagar o favorito de A.
-- ---------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims to '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select is(
  (select count(*) from public.favorites where user_id = '11111111-1111-1111-1111-111111111111'),
  0::bigint,
  'favorites: B não enxerga o favorito de A (SELECT)'
);

select throws_ok(
  $$ insert into public.favorites (user_id, restaurant_id) values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001') $$,
  '42501',
  'favorites: B não pode inserir favorito em nome de A (INSERT)'
);

select is(
  (with deleted as (
    delete from public.favorites where id = 'dddddddd-0000-0000-0000-000000000001' returning id
  ) select count(*) from deleted),
  0::bigint,
  'favorites: B não pode apagar o favorito de A (DELETE)'
);

-- ---------------------------------------------------------------------
-- notifications: A é destinatário; B nunca deve ler/marcar como lida/
-- inserir em nome de A (INSERT é bloqueado até para o próprio dono -
-- só o trigger SECURITY DEFINER escreve aqui).
-- ---------------------------------------------------------------------

select is(
  (select count(*) from public.notifications where user_id = '11111111-1111-1111-1111-111111111111'),
  0::bigint,
  'notifications: B não enxerga a notificação de A (SELECT)'
);

select is(
  (with updated as (
    update public.notifications set is_read = true
    where id = 'eeeeeeee-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'notifications: B não pode marcar como lida a notificação de A (UPDATE)'
);

select throws_ok(
  $$ insert into public.notifications (user_id, type, title, message) values ('22222222-2222-2222-2222-222222222222', 'new_follower', 'x', 'x') $$,
  '42501',
  'notifications: cliente autenticado não pode inserir notificação nem em nome próprio (INSERT reservado ao trigger)'
);

-- ---------------------------------------------------------------------
-- notification_preferences: A é dono; B nunca deve ler/alterar.
-- ---------------------------------------------------------------------

select is(
  (select count(*) from public.notification_preferences where user_id = '11111111-1111-1111-1111-111111111111'),
  0::bigint,
  'notification_preferences: B não enxerga a preferência de A (SELECT)'
);

select throws_ok(
  $$ insert into public.notification_preferences (user_id, category) values ('11111111-1111-1111-1111-111111111111', 'restaurants') $$,
  '42501',
  'notification_preferences: B não pode inserir preferência em nome de A (INSERT)'
);

select is(
  (with updated as (
    update public.notification_preferences set in_app_enabled = false
    where id = 'ffffffff-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'notification_preferences: B não pode alterar a preferência de A (UPDATE)'
);

-- ---------------------------------------------------------------------
-- comment_reports: A é autor da denúncia; B (não-admin) nunca deve ler.
-- ---------------------------------------------------------------------

select is(
  (select count(*) from public.comment_reports where reported_by = '11111111-1111-1111-1111-111111111111'),
  0::bigint,
  'comment_reports: B (não-admin) não enxerga a denúncia de A (SELECT)'
);

select throws_ok(
  $$ insert into public.comment_reports (comment_id, reported_by, reason) values ('cccccccc-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'x') $$,
  '42501',
  'comment_reports: B não pode denunciar em nome de A (INSERT)'
);

-- ---------------------------------------------------------------------
-- feedback: A é autor; B nunca deve ler/alterar/apagar.
-- ---------------------------------------------------------------------

select is(
  (select count(*) from public.feedback where user_id = '11111111-1111-1111-1111-111111111111'),
  0::bigint,
  'feedback: B não enxerga o feedback de A (SELECT)'
);

select throws_ok(
  $$ insert into public.feedback (user_id, message) values ('11111111-1111-1111-1111-111111111111', 'x') $$,
  '42501',
  'feedback: B não pode enviar feedback em nome de A (INSERT)'
);

-- Diferente de favorites/notifications (que têm GRANT de DELETE e por
-- isso falham silenciosamente via RLS), feedback não tem NENHUM GRANT
-- de DELETE (ver migration 20260725110000) - a tentativa falha antes
-- mesmo de a RLS ser avaliada, lançando erro de permissão.
select throws_ok(
  $$ delete from public.feedback where id = '22222222-0000-0000-0000-000000000001' $$,
  '42501',
  'feedback: ninguém pode apagar (DELETE - sem GRANT, nem para o próprio autor)'
);

-- ---------------------------------------------------------------------
-- user_roles: usuário comum (A e B, nenhum administrador) nunca vê
-- nenhuma linha, nem mesmo tentando inserir seu próprio papel.
-- ---------------------------------------------------------------------

select is(
  (select count(*) from public.user_roles),
  0::bigint,
  'user_roles: usuário comum não enxerga nenhuma linha da tabela (SELECT), mesmo sem ser admin'
);

select throws_ok(
  $$ insert into public.user_roles (user_id, role) values ('22222222-2222-2222-2222-222222222222', 'super_admin') $$,
  '42501',
  'user_roles: usuário comum não pode se auto-promover a super_admin (INSERT)'
);

-- ---------------------------------------------------------------------
-- audit_logs: usuário comum nunca lê nem insere em nome de outro.
-- ---------------------------------------------------------------------

select is(
  (select count(*) from public.audit_logs),
  0::bigint,
  'audit_logs: usuário comum não enxerga nenhuma linha (SELECT)'
);

select throws_ok(
  $$ insert into public.audit_logs (actor_id, action, entity, entity_id) values ('22222222-2222-2222-2222-222222222222', 'x', 'x', '11111111-1111-1111-1111-111111111111') $$,
  '42501',
  'audit_logs: usuário comum não pode registrar uma auditoria (INSERT reservado a admin)'
);

-- ---------------------------------------------------------------------
-- Confirma, do lado do dono (A), que o acesso ao PRÓPRIO dado continua
-- funcionando normalmente - a suíte acima não é falso-positivo por
-- bloquear geral demais.
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select is(
  (select count(*) from public.favorites where id = 'dddddddd-0000-0000-0000-000000000001'),
  1::bigint,
  'favorites: A enxerga o próprio favorito (SELECT)'
);

select is(
  (select count(*) from public.notifications where id = 'eeeeeeee-0000-0000-0000-000000000001'),
  1::bigint,
  'notifications: A enxerga a própria notificação (SELECT)'
);

select is(
  (with updated as (
    update public.notifications set is_read = true
    where id = 'eeeeeeee-0000-0000-0000-000000000001'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'notifications: A pode marcar como lida a própria notificação (UPDATE)'
);

select is(
  (select count(*) from public.notification_preferences where id = 'ffffffff-0000-0000-0000-000000000001'),
  1::bigint,
  'notification_preferences: A enxerga a própria preferência (SELECT)'
);

select is(
  (select count(*) from public.comment_reports where id = '11111111-0000-0000-0000-000000000001'),
  1::bigint,
  'comment_reports: A enxerga a própria denúncia (SELECT)'
);

select is(
  (select count(*) from public.feedback where id = '22222222-0000-0000-0000-000000000001'),
  1::bigint,
  'feedback: A enxerga o próprio feedback (SELECT)'
);

select * from finish();

rollback;
