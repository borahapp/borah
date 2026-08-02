-- BLOCO 7 - Estatísticas (faltas do usuário)
--
-- "Presenças"/"Faltas" (pedido original, Estatísticas > Usuário) -
-- "presenças" já é `group_members.events_count` (BLOCO 5); faltava
-- "faltas" (recusas). Em vez de criar um trigger novo, estende
-- `recalculate_member_events_count()` (BLOCO 5) para calcular também
-- esta coluna - mesmo evento (`event_attendances` insert/update/
-- delete) já dispara a atualização certa, então é uma coluna a mais no
-- mesmo UPDATE, não uma consulta a mais. `CREATE OR REPLACE FUNCTION`
-- com o corpo estendido - mesmo padrão de correção retroativa já usado
-- em `20260720130015_fix_recalculate_triggers_security_definer.sql`
-- (a trigger existente continua apontando para a mesma função,
-- automaticamente).

alter table public.group_members add column declined_count integer not null default 0;

create or replace function public.recalculate_member_events_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  affected_user_id uuid;
  affected_group_id uuid;
begin
  affected_user_id := coalesce(new.user_id, old.user_id);

  select group_id into affected_group_id
  from public.events
  where id = coalesce(new.event_id, old.event_id);

  update public.group_members
  set
    events_count = (
      select count(*)
      from public.event_attendances ea
      join public.events e on e.id = ea.event_id
      where e.group_id = affected_group_id
        and ea.user_id = affected_user_id
        and ea.status = 'confirmed'
    ),
    declined_count = (
      select count(*)
      from public.event_attendances ea
      join public.events e on e.id = ea.event_id
      where e.group_id = affected_group_id
        and ea.user_id = affected_user_id
        and ea.status = 'declined'
    )
  where group_id = affected_group_id and user_id = affected_user_id;

  return coalesce(new, old);
end;
$$;
