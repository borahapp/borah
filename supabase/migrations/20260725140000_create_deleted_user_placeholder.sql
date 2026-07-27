-- RC-04C - LGPD & Account Deletion
--
-- Cria a conta de sistema "Usuário removido" - destino de reatribuição
-- de autoria (reviews/comments/comment_reports/restaurants/audit_logs)
-- quando um usuário exclui a própria conta (ver
-- 20260725150000_create_delete_own_account_function.sql).
--
-- Por que isto é necessário: sem uma conta fixa para reatribuir, excluir
-- QUALQUER usuário que já escreveu uma avaliação/comentário/denúncia,
-- criado um restaurante, ou realizado qualquer ação administrativa
-- logada seria BLOQUEADO pela integridade referencial -
-- `reviews.user_id`/`comments.user_id`/`comment_reports.reported_by`/
-- `audit_logs.actor_id` são `on delete restrict`; `restaurants.
-- created_by` não tem nenhuma cláusula de cascata (equivale a bloquear).
-- Isso não é um caso raro - é o caso normal de qualquer usuário que já
-- usou o app de verdade.
--
-- Decisão arquitetural aprovada explicitamente pelo usuário: reatribuir
-- a autoria em vez de apagar o conteúdo. Apagar em cascata destruiria
-- dados de OUTROS usuários (curtidas, comentários, avaliações de
-- terceiros no mesmo restaurante) - a avaliação/comentário/restaurante
-- em si não é considerado dado pessoal do autor original uma vez que a
-- autoria é anonimizada; o texto/nota/restaurante permanece visível
-- para quem já interagiu com ele.
--
-- Esta conta nunca pode ser usada para login: `encrypted_password`
-- recebe um hash bcrypt de um UUID aleatório gerado e descartado
-- imediatamente na própria expressão - ninguém jamais conhece (nem
-- pode reconstruir) a senha correspondente.
--
-- ATENCAO: como toda migration deste projeto, escrita e revisada
-- estaticamente, sem validação contra uma instância real do
-- Supabase/Postgres (ver AR-06/EX-01B).

create extension if not exists pgcrypto;

insert into auth.users (
  id, email, encrypted_password, email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, aud, role
)
values (
  '00000000-0000-0000-0000-000000000001',
  'deleted-user@borah.internal',
  extensions.crypt(
    gen_random_uuid()::text,
    extensions.gen_salt('bf')
  ),
  now(), now(), now(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  'authenticated',
  'authenticated'
)
on conflict (id) do nothing;

-- `handle_new_user()` (trigger em auth.users, DV-02) já criou a linha
-- correspondente de `public.profiles` automaticamente - só ajustamos o
-- nome de exibição.
update public.profiles
set full_name = 'Usuário removido'
where id = '00000000-0000-0000-0000-000000000001';

-- ---------------------------------------------------------------------
-- Sem estas duas trocas, a reatribuição em massa para esta única conta
-- eventualmente violaria as constraints UNIQUE existentes: o segundo
-- usuário que excluir a conta, após ter avaliado o MESMO restaurante
-- (ou denunciado o MESMO comentário) que um usuário anteriormente
-- excluído também avaliou/denunciou, geraria um conflito de chave
-- duplicada (user_id+restaurant_id / comment_id+reported_by repetidos
-- para a conta placeholder). A regra original "um usuário só avalia/
-- denuncia uma vez o mesmo alvo" nunca fez sentido para uma conta que
-- não representa uma pessoa real - por isso a unicidade agora exclui
-- especificamente esta conta, via índice único parcial, em vez do
-- `unique` de tabela original (Postgres não permite adicionar uma
-- cláusula WHERE a uma constraint já existente - por isso a troca por
-- um índice).
-- ---------------------------------------------------------------------

alter table public.reviews drop constraint reviews_user_restaurant_unique;
create unique index reviews_user_restaurant_unique
  on public.reviews (user_id, restaurant_id)
  where user_id <> '00000000-0000-0000-0000-000000000001';

alter table public.comment_reports drop constraint comment_reports_unique;
create unique index comment_reports_unique
  on public.comment_reports (comment_id, reported_by)
  where reported_by <> '00000000-0000-0000-0000-000000000001';
