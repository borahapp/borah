-- Correção operacional - Bug 2 da Validação Funcional do Backend (2026-07-20)
--
-- `recalculate_restaurant_rating()` (criada em
-- 20260718230545_create_reviews_average_rating_trigger.sql) e
-- `recalculate_review_likes_count()` (mesma migration) não eram
-- SECURITY DEFINER - o UPDATE interno rodava com o privilégio de quem
-- disparou o INSERT/UPDATE/DELETE original, sujeito à RLS de
-- `restaurants`/`reviews` (`restaurants_update_own`/`reviews_update_own`,
-- que só permitem o dono). Como quem avalia um restaurante ou curte uma
-- avaliação quase nunca é o dono do restaurante/da avaliação, o UPDATE
-- de recálculo era silenciosamente filtrado pela RLS (0 linhas afetadas,
-- sem erro) - confirmado empiricamente: `average_rating`/`total_reviews`
-- e `likes_count` nunca refletiam a realidade no caso cross-user.
--
-- Corrigido com o mesmo padrão já usado com sucesso em outras 8 funções
-- deste projeto (`handle_new_user`, `create_notification`,
-- `notify_new_follower/comment/like`, `award_badge`,
-- `award_gamification_points`, `handle_gamification_new_review/comment/
-- like`): SECURITY DEFINER faz a consulta/escrita interna rodar com o
-- privilégio do dono da função (bypassando a RLS de quem apenas disparou
-- o evento), com `search_path` travado para evitar sequestro de schema.
--
-- Apenas `CREATE OR REPLACE FUNCTION` - o corpo é idêntico ao original,
-- só adiciona `security definer set search_path`. As triggers já
-- existentes continuam apontando para a mesma função automaticamente,
-- sem precisar ser recriadas.

create or replace function public.recalculate_restaurant_rating()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  affected_restaurant_id uuid;
begin
  affected_restaurant_id := coalesce(new.restaurant_id, old.restaurant_id);

  update public.restaurants
  set
    average_rating = (
      select avg(rating) from public.reviews
      where restaurant_id = affected_restaurant_id and deleted_at is null
    ),
    total_reviews = (
      select count(*) from public.reviews
      where restaurant_id = affected_restaurant_id and deleted_at is null
    )
  where id = affected_restaurant_id;

  return coalesce(new, old);
end;
$$;

create or replace function public.recalculate_review_likes_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  affected_review_id uuid;
begin
  affected_review_id := coalesce(new.review_id, old.review_id);

  update public.reviews
  set likes_count = (
    select count(*) from public.review_likes
    where review_id = affected_review_id
  )
  where id = affected_review_id;

  return coalesce(new, old);
end;
$$;
