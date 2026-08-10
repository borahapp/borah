-- FASE SOCIAL 3 - groups.member_count
--
-- Mantido por trigger (AFTER INSERT/DELETE em group_members), nunca por
-- COUNT(*) em tempo de leitura - mesmo princípio de
-- adjust_follow_counters (FASE SOCIAL 2) / recalculate_restaurant_rating.
--
-- Por que uma coluna denormalizada em `groups`, não abrir RLS de
-- `group_members`: a decisão de produto desta fase é que um não-membro
-- só vê a QUANTIDADE de membros de um grupo public, nunca a lista -
-- group_members_select_members (GROUP-01) continua fechada a
-- não-membros. Sem esta coluna não haveria como um não-membro saber
-- "quantos membros" sem consultar group_members diretamente.
--
-- Reconciliação inicial: group_members já tem linhas quando esta
-- migration roda.

alter table public.groups
  add column member_count integer not null default 0
    check (member_count >= 0);

update public.groups g
set member_count = coalesce((
  select count(*) from public.group_members m where m.group_id = g.id
), 0);

create function public.adjust_group_member_count()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.groups set member_count = member_count + 1 where id = new.group_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.groups set member_count = member_count - 1 where id = old.group_id;
    return old;
  end if;
  return null;
end;
$$;

-- Funcao de trigger interna (nunca chamada direto por RPC do cliente) -
-- mesmo padrão de adjust_follow_counters/notify_new_follower: só `SET
-- search_path`, sem REVOKE/GRANT EXECUTE.
create trigger adjust_group_member_count_trigger
  after insert or delete on public.group_members
  for each row execute procedure public.adjust_group_member_count();
