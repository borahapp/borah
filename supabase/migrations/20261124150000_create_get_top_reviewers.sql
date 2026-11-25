-- Rodada "perfil individual como centro" (pós-FASE 09) - Item E: Ranking
-- de Avaliadores (quem mais avaliou restaurantes).
--
-- Diferente de `profiles.followers_count`/`following_count`
-- (20260809160015) e `group_members.reviews_count`
-- (20260801110000) - que são contadores incrementais mantidos por
-- trigger a cada escrita - aqui a decisão é NÃO denormalizar: contar
-- quantas vezes CADA usuário aparece em `reviews` e ordenar
-- globalmente por isso é uma agregação (`GROUP BY` + `ORDER BY count`)
-- que o PostgREST não expõe sobre uma tabela simples, mas que também
-- não precisa de um contador sempre atualizado (mesmo raciocínio de
-- `recalculate_restaurant_rating`, 20260718230545: recalcula do zero
-- em vez de incrementar/decrementar, só que aqui como função só-leitura,
-- sem trigger nenhum - ninguém mais, além desta tela de ranking, lê
-- "quantas avaliações cada usuário tem" agregado globalmente).
--
-- `security invoker` (padrão, sem `security definer`) - RLS de
-- `reviews`/`profiles` já permite SELECT a qualquer autenticado
-- ("reviews_select_authenticated"/"profiles_select_authenticated"),
-- então a função roda com os privilégios normais de quem chama, sem
-- precisar bypassar RLS.
create function public.get_top_reviewers(p_limit integer, p_offset integer)
returns table (user_id uuid, full_name text, reviews_count bigint)
language sql
stable
as $$
  select p.id, p.full_name, count(r.id)
  from public.reviews r
  join public.profiles p on p.id = r.user_id
  where r.deleted_at is null
  group by p.id, p.full_name
  order by count(r.id) desc, p.id
  limit p_limit offset p_offset;
$$;

revoke execute on function public.get_top_reviewers(integer, integer) from public;
grant execute on function public.get_top_reviewers(integer, integer) to authenticated;
