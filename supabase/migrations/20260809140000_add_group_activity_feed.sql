-- RC-03 F25 - Feed automático de atividade do grupo.
--
-- Recomendação já registrada em RC03_FEATURE_GAP.md §6 item 3: construir
-- sobre `notifications`, não sobre uma segunda fonte de eventos paralela -
-- a tabela já registra exatamente os eventos que um "feed de grupo"
-- mostraria (novo rolê, resposta de presença, novo membro), só que hoje
-- por destinatário (`user_id`), nunca por grupo.
--
-- `notifications` NÃO tem coluna `group_id` - o id do grupo vive dentro
-- de `payload` (`jsonb_build_object('group_id', ...)`, já usado pelos 3
-- triggers de `20260801130000_add_group_event_notifications.sql`).
-- Eventos com fan-out (`notify_new_event`, 1 linha POR membro) geram
-- várias linhas idênticas (mesmo `created_at`, mesmo `payload` - `now()`
-- é estável dentro da mesma execução de trigger) - sem o `distinct on`
-- abaixo, o feed mostraria "novo rolê criado" repetido N vezes.
--
-- `security definer` obrigatório: `notifications_select_own` restringe
-- SELECT a `auth.uid() = user_id` - sem bypass, o cliente não conseguiria
-- ver a atividade de outros membros de jeito nenhum.

create function public.group_activity_feed(
  p_group_id uuid,
  p_limit integer,
  p_offset integer
)
returns setof public.notifications
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
    select n.* from (
      select distinct on (dn.created_at, dn.payload) dn.*
      from public.notifications dn
      where dn.payload ->> 'group_id' = p_group_id::text
      order by dn.created_at, dn.payload
    ) n
    order by n.created_at desc
    limit p_limit offset p_offset;
end;
$$;

revoke execute on function public.group_activity_feed(uuid, integer, integer) from public;
grant execute on function public.group_activity_feed(uuid, integer, integer) to authenticated;
