-- RC-04B - Storage & Upload Security
-- Suíte de RLS cross-user para `storage.objects`, cobrindo os 3
-- buckets criados por `20260725120000_create_storage_buckets.sql`:
-- `avatars`, `restaurants`, `review-photos`.
--
-- COMO RODAR: `supabase start` (requer Docker), depois
-- `supabase test db --local supabase/tests/database`. Este arquivo NÃO
-- foi executado nem validado contra uma instância real - mesma
-- ressalva já registrada em `10_rls_private_tables.test.sql`/
-- `20_rls_public_read_own_write.test.sql`/`30_rls_admin_permissions.
-- test.sql` (RC-04A) - escrito e revisado estaticamente, seguindo o
-- mesmo padrão pgTAP oficial do Supabase.
--
-- Convenção idêntica à das demais suítes de RLS deste projeto: INSERT
-- indevido usa `throws_ok(..., '42501')` (falha de WITH CHECK sempre
-- lança); SELECT/UPDATE/DELETE indevidos usam contagem de linhas
-- (a cláusula USING nega tornando a linha invisível, sem lançar
-- exceção). Buckets já existem neste ponto (criados pela migration,
-- aplicada antes desta suíte rodar) - não são recriados aqui.
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
  ('11111111-1111-1111-1111-111111111111', 'user-a@storage-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 'user-b@storage-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'moderator@storage-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.user_roles (user_id, role) values
  ('55555555-5555-5555-5555-555555555555', 'moderator')
on conflict (user_id) do nothing;

insert into public.restaurants (id, name, category, created_by)
values ('aaaaaaaa-0000-0000-0000-000000000010', 'Restaurante RLS Storage Test', 'test', '11111111-1111-1111-1111-111111111111')
on conflict (id) do nothing;

insert into public.reviews (id, restaurant_id, user_id, rating, comment)
values ('bbbbbbbb-0000-0000-0000-000000000010', 'aaaaaaaa-0000-0000-0000-000000000010', '11111111-1111-1111-1111-111111111111', 5, 'ótimo')
on conflict (id) do nothing;

-- Arquivos já existentes, pertencentes a A.
insert into storage.objects (bucket_id, name, owner)
values
  ('avatars', '11111111-1111-1111-1111-111111111111/avatar.jpg', '11111111-1111-1111-1111-111111111111'),
  ('restaurants', 'aaaaaaaa-0000-0000-0000-000000000010/cover.jpg', '11111111-1111-1111-1111-111111111111'),
  ('review-photos', 'bbbbbbbb-0000-0000-0000-000000000010/photo-1.jpg', '11111111-1111-1111-1111-111111111111'),
  ('review-photos', 'bbbbbbbb-0000-0000-0000-000000000010/photo-2.jpg', '11111111-1111-1111-1111-111111111111')
on conflict do nothing;

-- ---------------------------------------------------------------------
-- avatars: leitura de qualquer autenticado (mesmo modelo de
-- `public.profiles`); escrita restrita ao dono (pasta = auth.uid()).
-- ---------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims to '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select is(
  (select count(*) from storage.objects where name = '11111111-1111-1111-1111-111111111111/avatar.jpg'),
  1::bigint,
  'avatars: B consegue ler o avatar de A (SELECT público, por design)'
);

select throws_ok(
  $$ insert into storage.objects (bucket_id, name, owner) values ('avatars', '11111111-1111-1111-1111-111111111111/hack.jpg', '22222222-2222-2222-2222-222222222222') $$,
  '42501',
  'avatars: B não pode inserir na pasta de A (INSERT)'
);

select is(
  (with updated as (
    update storage.objects set name = name
    where name = '11111111-1111-1111-1111-111111111111/avatar.jpg' and bucket_id = 'avatars'
    returning name
  ) select count(*) from updated),
  0::bigint,
  'avatars: B não pode alterar o avatar de A (UPDATE)'
);

select is(
  (with deleted as (
    delete from storage.objects
    where name = '11111111-1111-1111-1111-111111111111/avatar.jpg' and bucket_id = 'avatars'
    returning name
  ) select count(*) from deleted),
  0::bigint,
  'avatars: B não pode apagar o avatar de A (DELETE)'
);

set local request.jwt.claims to '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select is(
  (with updated as (
    update storage.objects set name = name
    where name = '11111111-1111-1111-1111-111111111111/avatar.jpg' and bucket_id = 'avatars'
    returning name
  ) select count(*) from updated),
  1::bigint,
  'avatars: A pode alterar o próprio avatar (UPDATE)'
);

select is(
  (with deleted as (
    delete from storage.objects
    where name = '11111111-1111-1111-1111-111111111111/avatar.jpg' and bucket_id = 'avatars'
    returning name
  ) select count(*) from deleted),
  1::bigint,
  'avatars: A pode apagar o próprio avatar (DELETE)'
);

-- ---------------------------------------------------------------------
-- restaurants: leitura pública; escrita restrita a quem criou o
-- restaurante OU administrador/moderador (can_moderate()).
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select is(
  (select count(*) from storage.objects where name = 'aaaaaaaa-0000-0000-0000-000000000010/cover.jpg'),
  1::bigint,
  'restaurants: B consegue ler a capa do restaurante de A (SELECT público, por design)'
);

select throws_ok(
  $$ insert into storage.objects (bucket_id, name, owner) values ('restaurants', 'aaaaaaaa-0000-0000-0000-000000000010/hack.jpg', '22222222-2222-2222-2222-222222222222') $$,
  '42501',
  'restaurants: B (não é dono nem moderador) não pode inserir na pasta do restaurante de A (INSERT)'
);

select is(
  (with updated as (
    update storage.objects set name = name
    where name = 'aaaaaaaa-0000-0000-0000-000000000010/cover.jpg' and bucket_id = 'restaurants'
    returning name
  ) select count(*) from updated),
  0::bigint,
  'restaurants: B (não é dono nem moderador) não pode alterar a capa (UPDATE)'
);

select is(
  (with deleted as (
    delete from storage.objects
    where name = 'aaaaaaaa-0000-0000-0000-000000000010/cover.jpg' and bucket_id = 'restaurants'
    returning name
  ) select count(*) from deleted),
  0::bigint,
  'restaurants: B (não é dono nem moderador) não pode apagar a capa (DELETE)'
);

set local request.jwt.claims to '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}';

select is(
  (with updated as (
    update storage.objects set name = name
    where name = 'aaaaaaaa-0000-0000-0000-000000000010/cover.jpg' and bucket_id = 'restaurants'
    returning name
  ) select count(*) from updated),
  1::bigint,
  'restaurants: moderador pode alterar a capa de um restaurante de outro usuário (UPDATE, can_moderate())'
);

set local request.jwt.claims to '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select is(
  (with updated as (
    update storage.objects set name = name
    where name = 'aaaaaaaa-0000-0000-0000-000000000010/cover.jpg' and bucket_id = 'restaurants'
    returning name
  ) select count(*) from updated),
  1::bigint,
  'restaurants: A (dono) pode alterar a própria capa (UPDATE)'
);

select is(
  (with deleted as (
    delete from storage.objects
    where name = 'aaaaaaaa-0000-0000-0000-000000000010/cover.jpg' and bucket_id = 'restaurants'
    returning name
  ) select count(*) from deleted),
  1::bigint,
  'restaurants: A (dono) pode apagar a própria capa (DELETE)'
);

-- ---------------------------------------------------------------------
-- review-photos: leitura pública; upload restrito ao autor da
-- avaliação; remoção também permitida a administrador/moderador (sem
-- policy de UPDATE - cada foto é um arquivo novo, nunca substituído).
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select is(
  (select count(*) from storage.objects where name = 'bbbbbbbb-0000-0000-0000-000000000010/photo-1.jpg'),
  1::bigint,
  'review-photos: B consegue ler a foto da avaliação de A (SELECT público, por design)'
);

select throws_ok(
  $$ insert into storage.objects (bucket_id, name, owner) values ('review-photos', 'bbbbbbbb-0000-0000-0000-000000000010/hack.jpg', '22222222-2222-2222-2222-222222222222') $$,
  '42501',
  'review-photos: B (não é autor da avaliação) não pode inserir uma foto (INSERT)'
);

select is(
  (with deleted as (
    delete from storage.objects
    where name = 'bbbbbbbb-0000-0000-0000-000000000010/photo-1.jpg' and bucket_id = 'review-photos'
    returning name
  ) select count(*) from deleted),
  0::bigint,
  'review-photos: B (não é autor nem moderador) não pode apagar a foto (DELETE)'
);

set local request.jwt.claims to '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}';

select is(
  (with deleted as (
    delete from storage.objects
    where name = 'bbbbbbbb-0000-0000-0000-000000000010/photo-2.jpg' and bucket_id = 'review-photos'
    returning name
  ) select count(*) from deleted),
  1::bigint,
  'review-photos: moderador pode remover uma foto imprópria de outro usuário (DELETE, can_moderate())'
);

set local request.jwt.claims to '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select is(
  (with deleted as (
    delete from storage.objects
    where name = 'bbbbbbbb-0000-0000-0000-000000000010/photo-1.jpg' and bucket_id = 'review-photos'
    returning name
  ) select count(*) from deleted),
  1::bigint,
  'review-photos: A (autor da avaliação) pode apagar a própria foto (DELETE)'
);

select * from finish();

rollback;
