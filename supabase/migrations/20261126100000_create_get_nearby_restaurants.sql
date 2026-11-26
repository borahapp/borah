-- Item G - sugestão de restaurantes por localização em Explorar.
--
-- Sem PostGIS instalado neste projeto - mesma decisão já tomada em
-- `get_group_restaurant_ranking`/`get_top_reviewers`: fórmula de
-- haversine simples em SQL puro, sem extensão nova. Só considera
-- restaurantes com `latitude`/`longitude` preenchidos - hoje só os
-- vindos da busca do Google Places (F12) têm coordenadas; cadastro
-- manual não pede lat/lng, mesma limitação já aceita para
-- city/state/country.
--
-- `security invoker` (não `definer`): `restaurants` já é legível por
-- qualquer autenticado (`restaurants_select_authenticated`), não há
-- nenhuma tabela extra a contornar aqui, diferente de
-- `suggest_group_restaurants`/`get_group_restaurant_ranking`.

create function public.get_nearby_restaurants(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision default 20,
  p_limit integer default 10,
  p_offset integer default 0
)
returns table (
  restaurant_id uuid,
  name text,
  category text,
  city text,
  cover_image text,
  average_rating numeric,
  total_reviews integer,
  distance_km double precision
)
language sql
stable
as $$
  select *
  from (
    select
      r.id as restaurant_id,
      r.name,
      r.category,
      r.city,
      r.cover_image,
      r.average_rating,
      r.total_reviews,
      6371 * acos(
        least(1, greatest(-1,
          cos(radians(p_lat)) * cos(radians(r.latitude))
            * cos(radians(r.longitude) - radians(p_lng))
            + sin(radians(p_lat)) * sin(radians(r.latitude))
        ))
      ) as distance_km
    from public.restaurants r
    where r.deleted_at is null
      and r.status = 'active'
      and r.latitude is not null
      and r.longitude is not null
  ) nearby
  where distance_km <= p_radius_km
  order by distance_km asc
  limit p_limit offset p_offset;
$$;

revoke execute on function public.get_nearby_restaurants(
  double precision, double precision, double precision, integer, integer
) from public;
grant execute on function public.get_nearby_restaurants(
  double precision, double precision, double precision, integer, integer
) to authenticated;
