-- DV-04 - Reviews Module (trigger de dominio)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Diferente de `set_updated_at()` (infraestrutura generica, reutilizavel
-- por qualquer tabela), estas duas funcoes pertencem ao dominio de
-- avaliacoes: uma mantem `restaurants.average_rating`/`total_reviews`
-- consistentes com `reviews`; a outra mantem `reviews.likes_count`
-- consistente com `review_likes`. Nao ha como generalizar essa logica de
-- recalculo para outras tabelas sem SQL dinamico, entao nascem aqui,
-- especificas, em vez de virarem "infraestrutura compartilhada".
--
-- Recalcula do zero (em vez de incrementar/decrementar) a cada evento,
-- para evitar divergencia acumulada entre o contador e a realidade.
-- Considera apenas avaliacoes com deleted_at is null.

create function public.recalculate_restaurant_rating()
returns trigger
language plpgsql
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

create trigger recalculate_restaurant_rating_on_review_change
  after insert or update or delete on public.reviews
  for each row execute procedure public.recalculate_restaurant_rating();

create function public.recalculate_review_likes_count()
returns trigger
language plpgsql
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

create trigger recalculate_review_likes_count_on_like_change
  after insert or delete on public.review_likes
  for each row execute procedure public.recalculate_review_likes_count();
