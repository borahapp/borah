-- Ranking multi-escopo de restaurantes (Item F), escopo "Grupo": restaurantes
-- dos rolês (`events`) do grupo, ordenados pela média das avaliações
-- coletivas (`event_reviews`) registradas para esses rolês - decisão
-- aprovada entre as 2 alternativas levantadas (reaproveitar `events`/
-- `event_reviews` em vez de cruzar `reviews` individuais com
-- `group_members`, mais pesado e menos fiel ao conceito de "o grupo foi
-- lá e avaliou").
--
-- `security definer` necessário pelo mesmo motivo de
-- `suggest_group_restaurants` (20260809130000): o cliente não pode
-- verificar membresia de outro usuário via `group_members` diretamente
-- por RLS - a checagem de `is_group_member` substitui isso. Sem
-- agregação denormalizada (mesma decisão de `get_top_reviewers`,
-- 20261124150000): ranking por grupo é consultado raramente, não
-- justifica contador mantido por trigger.
--
-- Agrega direto sobre `event_reviews` (nunca sobre `events.average_rating`,
-- que já é uma média por evento) para não enviesar a média quando um
-- mesmo restaurante tem rolês com quantidades de avaliações bem
-- diferentes entre si.

create function public.get_group_restaurant_ranking(
  p_group_id uuid,
  p_city text default null,
  p_state text default null,
  p_country text default null,
  p_category text default null,
  p_limit integer default 20,
  p_offset integer default 0
)
returns table (
  restaurant_id uuid,
  name text,
  category text,
  city text,
  state text,
  country text,
  cover_image text,
  average_rating numeric,
  total_reviews bigint
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_group_member(auth.uid(), p_group_id) then
    return;
  end if;

  return query
    select
      r.id,
      r.name,
      r.category,
      r.city,
      r.state,
      r.country,
      r.cover_image,
      avg(
        (er.food_score + er.service_score + er.ambience_score
          + er.cost_benefit_score + er.overall_score) / 5
      ) as average_rating,
      count(er.id) as total_reviews
    from public.restaurants r
    join public.events e on e.restaurant_id = r.id and e.group_id = p_group_id
    join public.event_reviews er on er.event_id = e.id
    where r.deleted_at is null
      and (p_city is null or p_city = '' or r.city = p_city)
      and (p_state is null or p_state = '' or r.state = p_state)
      and (p_country is null or p_country = '' or r.country = p_country)
      and (p_category is null or p_category = '' or r.category = p_category)
    group by r.id
    order by average_rating desc, total_reviews desc, r.name asc
    limit p_limit offset p_offset;
end;
$$;

revoke execute on function public.get_group_restaurant_ranking(
  uuid, text, text, text, text, integer, integer
) from public;
grant execute on function public.get_group_restaurant_ranking(
  uuid, text, text, text, text, integer, integer
) to authenticated;
