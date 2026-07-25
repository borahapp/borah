-- RC-04A - Security Hardening
-- Suíte de RLS: tabelas de leitura pública, escrita restrita ao dono
-- (profiles, restaurants, reviews, comments, followers, review_likes).
--
-- COMO RODAR: `supabase start` (requer Docker), depois
-- `supabase test db --local supabase/tests/database`. Este arquivo NÃO
-- foi executado nem validado contra uma instância real - ver a mesma
-- ressalva em `10_rls_private_tables.test.sql`.
--
-- Diferente do arquivo anterior, aqui a LEITURA cruzada (B lendo dados
-- de A) é o comportamento CORRETO e esperado (decisão de produto - ver
-- DV-02/03/04/07) - o que deve ser negado é ESCRITA (update/delete) de
-- B sobre uma linha que pertence a A. `DELETE` em restaurants/reviews/
-- comments não tem nem GRANT (nenhum client pode apagar fisicamente -
-- só soft delete via UPDATE), então a tentativa lança erro de
-- permissão (42501) antes mesmo da RLS ser avaliada - já `followers`/
-- `review_likes` têm GRANT de DELETE, então a negação vem da RLS
-- (0 linhas afetadas), não de uma exceção.
--
-- Toda a suíte roda dentro de uma transação revertida ao final.

begin;

select plan(23);

-- ---------------------------------------------------------------------
-- Fixtures (como `postgres`, bypassa RLS)
-- ---------------------------------------------------------------------

set local role postgres;

insert into auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('11111111-1111-1111-1111-111111111111', 'user-a@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 'user-b@rls-test.local', 'x', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated')
on conflict (id) do nothing;

-- profiles: populado automaticamente por handle_new_user() (trigger em
-- auth.users) - não precisa de INSERT manual.

insert into public.restaurants (id, name, category, created_by)
values ('aaaaaaaa-0000-0000-0000-000000000002', 'Restaurante RLS Test 2', 'test', '11111111-1111-1111-1111-111111111111')
on conflict (id) do nothing;

insert into public.reviews (id, restaurant_id, user_id, rating, comment)
values ('bbbbbbbb-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 4, 'muito bom')
on conflict (id) do nothing;

insert into public.comments (id, review_id, user_id, content)
values ('cccccccc-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'comentário de A')
on conflict (id) do nothing;

insert into public.followers (id, follower_id, following_id)
values ('dddddddd-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')
on conflict (id) do nothing;

insert into public.review_likes (review_id, user_id)
values ('bbbbbbbb-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111')
on conflict do nothing;

-- ---------------------------------------------------------------------
-- Como B: leitura cruzada deve funcionar; escrita cruzada deve ser negada.
-- ---------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims to '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

-- profiles
select is(
  (select count(*) from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  1::bigint,
  'profiles: B consegue ler o perfil de A (SELECT público, por design)'
);

select is(
  (with updated as (
    update public.profiles set full_name = 'hack'
    where id = '11111111-1111-1111-1111-111111111111'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'profiles: B não pode alterar o perfil de A (UPDATE)'
);

-- restaurants
select is(
  (select count(*) from public.restaurants where id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  1::bigint,
  'restaurants: B consegue ler o restaurante de A (SELECT público, por design)'
);

select is(
  (with updated as (
    update public.restaurants set name = 'hack'
    where id = 'aaaaaaaa-0000-0000-0000-000000000002'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'restaurants: B (não-moderador) não pode alterar o restaurante de A (UPDATE)'
);

select throws_ok(
  $$ delete from public.restaurants where id = 'aaaaaaaa-0000-0000-0000-000000000002' $$,
  '42501',
  'restaurants: ninguém pode apagar fisicamente (DELETE - sem GRANT, sem policy)'
);

-- reviews
select is(
  (select count(*) from public.reviews where id = 'bbbbbbbb-0000-0000-0000-000000000002'),
  1::bigint,
  'reviews: B consegue ler a avaliação de A (SELECT público, por design)'
);

select is(
  (with updated as (
    update public.reviews set comment = 'hack'
    where id = 'bbbbbbbb-0000-0000-0000-000000000002'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'reviews: B (não-moderador) não pode alterar a avaliação de A (UPDATE)'
);

select throws_ok(
  $$ delete from public.reviews where id = 'bbbbbbbb-0000-0000-0000-000000000002' $$,
  '42501',
  'reviews: ninguém pode apagar fisicamente (DELETE - sem GRANT, sem policy)'
);

-- comments
select is(
  (select count(*) from public.comments where id = 'cccccccc-0000-0000-0000-000000000002'),
  1::bigint,
  'comments: B consegue ler o comentário de A (SELECT público, por design)'
);

select is(
  (with updated as (
    update public.comments set content = 'hack'
    where id = 'cccccccc-0000-0000-0000-000000000002'
    returning id
  ) select count(*) from updated),
  0::bigint,
  'comments: B (não-moderador) não pode alterar o comentário de A (UPDATE)'
);

select throws_ok(
  $$ delete from public.comments where id = 'cccccccc-0000-0000-0000-000000000002' $$,
  '42501',
  'comments: ninguém pode apagar fisicamente (DELETE - sem GRANT, sem policy)'
);

-- followers
select is(
  (select count(*) from public.followers where follower_id = '11111111-1111-1111-1111-111111111111'),
  1::bigint,
  'followers: B consegue ler quem A segue (SELECT público, por design)'
);

select throws_ok(
  $$ insert into public.followers (follower_id, following_id) values ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222') $$,
  '42501',
  'followers: B não pode fazer A seguir alguém em nome dele (INSERT)'
);

select is(
  (with deleted as (
    delete from public.followers where id = 'dddddddd-0000-0000-0000-000000000002' returning id
  ) select count(*) from deleted),
  0::bigint,
  'followers: B não pode remover o "segue" de A (DELETE)'
);

-- review_likes
select is(
  (select count(*) from public.review_likes where review_id = 'bbbbbbbb-0000-0000-0000-000000000002' and user_id = '11111111-1111-1111-1111-111111111111'),
  1::bigint,
  'review_likes: B consegue ler a curtida de A (SELECT público, por design)'
);

select throws_ok(
  $$ insert into public.review_likes (review_id, user_id) values ('bbbbbbbb-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111') $$,
  '42501',
  'review_likes: B não pode curtir em nome de A (INSERT)'
);

select is(
  (with deleted as (
    delete from public.review_likes
    where review_id = 'bbbbbbbb-0000-0000-0000-000000000002' and user_id = '11111111-1111-1111-1111-111111111111'
    returning review_id
  ) select count(*) from deleted),
  0::bigint,
  'review_likes: B não pode descurtir em nome de A (DELETE)'
);

-- ---------------------------------------------------------------------
-- Sanity check: como A, o próprio dado continua editável/removível
-- normalmente - confirma que a suíte acima não é um falso-positivo por
-- bloquear geral demais.
-- ---------------------------------------------------------------------

set local request.jwt.claims to '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select is(
  (with updated as (
    update public.profiles set full_name = 'User A'
    where id = '11111111-1111-1111-1111-111111111111'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'profiles: A pode alterar o próprio perfil (UPDATE)'
);

select is(
  (with updated as (
    update public.restaurants set description = 'atualizado por A'
    where id = 'aaaaaaaa-0000-0000-0000-000000000002'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'restaurants: A pode alterar o próprio restaurante (UPDATE)'
);

select is(
  (with updated as (
    update public.reviews set comment = 'atualizado por A'
    where id = 'bbbbbbbb-0000-0000-0000-000000000002'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'reviews: A pode alterar a própria avaliação (UPDATE)'
);

select is(
  (with updated as (
    update public.comments set content = 'atualizado por A'
    where id = 'cccccccc-0000-0000-0000-000000000002'
    returning id
  ) select count(*) from updated),
  1::bigint,
  'comments: A pode alterar o próprio comentário dentro da janela de edição (UPDATE)'
);

select is(
  (with deleted as (
    delete from public.followers where id = 'dddddddd-0000-0000-0000-000000000002' returning id
  ) select count(*) from deleted),
  1::bigint,
  'followers: A pode deixar de seguir (DELETE)'
);

select is(
  (with deleted as (
    delete from public.review_likes
    where review_id = 'bbbbbbbb-0000-0000-0000-000000000002' and user_id = '11111111-1111-1111-1111-111111111111'
    returning review_id
  ) select count(*) from deleted),
  1::bigint,
  'review_likes: A pode descurtir a própria curtida (DELETE)'
);

select * from finish();

rollback;
