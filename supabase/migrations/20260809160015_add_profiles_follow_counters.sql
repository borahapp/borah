-- FASE SOCIAL 2 - profiles.followers_count / profiles.following_count
--
-- Mantidos por trigger (AFTER INSERT/DELETE em followers), nunca por
-- COUNT(*) em tempo de leitura - mesmo principio de
-- recalculate_restaurant_rating (20260718230545_create_reviews_average_rating_trigger.sql).
-- `UPDATE ... SET x = x + 1` e atomico no Postgres (sem race condition de
-- leitura-depois-escrita); o CHECK >= 0 e uma segunda trava contra o
-- contador ficar negativo por algum bug futuro.
--
-- Reconciliacao inicial: `followers` ja tem linhas quando esta migration
-- roda, entao as colunas nao podem simplesmente nascer zeradas - os 2
-- UPDATE abaixo calculam o valor real antes dos triggers assumirem a
-- manutencao incremental dai em diante.
--
-- Escrita direta pelo cliente: profiles ja tem
-- "grant select, insert, update on public.profiles to authenticated"
-- (20260720130000) e a funcao do trigger roda SECURITY DEFINER (bypassa
-- RLS como o dono da tabela, mesmo mecanismo ja usado por
-- notify_new_follower/recalculate_restaurant_rating) - nenhum GRANT novo
-- necessario. O cliente nunca tem motivo para enviar estas 2 colunas no
-- payload de update porque `UserProfileRepository.updateProfile` (Flutter)
-- nao expõe parametro para elas.

alter table public.profiles
  add column followers_count integer not null default 0
    check (followers_count >= 0);

alter table public.profiles
  add column following_count integer not null default 0
    check (following_count >= 0);

update public.profiles p
set followers_count = coalesce((
  select count(*) from public.followers f where f.following_id = p.id
), 0);

update public.profiles p
set following_count = coalesce((
  select count(*) from public.followers f where f.follower_id = p.id
), 0);

create function public.adjust_follow_counters()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.profiles set followers_count = followers_count + 1 where id = new.following_id;
    update public.profiles set following_count = following_count + 1 where id = new.follower_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.profiles set followers_count = followers_count - 1 where id = old.following_id;
    update public.profiles set following_count = following_count - 1 where id = old.follower_id;
    return old;
  end if;
  return null;
end;
$$;

-- Funcao de trigger interna (nunca chamada direto por RPC do cliente) -
-- mesmo padrao de notify_new_follower/recalculate_restaurant_rating:
-- so `SET search_path`, sem REVOKE/GRANT EXECUTE (esses dois existem
-- só nas funções pensadas para serem chamadas via `rpc()` pelo cliente,
-- como create_group/join_group_by_invite_code).
create trigger adjust_follow_counters_trigger
  after insert or delete on public.followers
  for each row execute procedure public.adjust_follow_counters();
