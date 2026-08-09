-- RC-03 F13 - Descoberta de restaurantes guiada pelo grupo.
--
-- `favorites` só é legível pelo próprio dono (`favorites_select_own`,
-- 20260719140000_create_favorites.sql) - agregar favoritos entre membros
-- de um grupo exige `security definer` (mesmo motivo de
-- `can_review_event`/`recalculate_event_rating`: o cliente não pode ver
-- favoritos de outros usuários diretamente via PostgREST). `restaurants`
-- já é legível por qualquer autenticado (`restaurants_select_authenticated`),
-- então só a parte de `favorites` precisa do bypass.
--
-- Sugere restaurantes favoritados por PELO MENOS 1 membro do grupo,
-- excluindo os que o grupo já visitou (já viraram `events`) - "ainda não
-- visitado pelo grupo" é o critério, não "nunca visitado por ninguém".
-- Sem tabela nova - query nova sobre dado já existente
-- (`RC03_FEATURE_GAP.md §4`: F13 não exige nenhuma infraestrutura nova).

create function public.suggest_group_restaurants(p_group_id uuid)
returns setof public.restaurants
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
    select r.*
    from public.restaurants r
    where r.deleted_at is null
      and r.status = 'active'
      and r.id in (
        select f.restaurant_id
        from public.favorites f
        join public.group_members gm on gm.user_id = f.user_id
        where gm.group_id = p_group_id
      )
      and r.id not in (
        select e.restaurant_id
        from public.events e
        where e.group_id = p_group_id
      )
    order by r.average_rating desc nulls last
    limit 10;
end;
$$;

revoke execute on function public.suggest_group_restaurants(uuid) from public;
grant execute on function public.suggest_group_restaurants(uuid) to authenticated;
