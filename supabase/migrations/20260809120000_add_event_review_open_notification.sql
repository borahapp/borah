-- FASE C.4 - Notificação de "Avaliação liberada"
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres nesta sessão
-- (mesma ressalva do restante do projeto).
--
-- Retomada do bloqueio registrado em
-- `20260801130000_add_group_event_notifications.sql`: "avaliação
-- liberada" foi deliberadamente deixada de fora daquela rodada porque
-- dependeria de um evento que não existe no Postgres (a passagem do
-- tempo até `scheduled_at`, sem nenhum job agendado - nenhuma extensão
-- `pg_cron` instalada, nenhuma Edge Function agendada). Essa condição
-- continua verdadeira; esta migration não instala nenhum scheduler.
--
-- Resolvido via "lazy": a RPC abaixo só é chamada explicitamente pelo
-- cliente (core/lazy_sync/, ver app), nunca por trigger - não existe
-- INSERT/UPDATE de banco que represente "o tempo passou". A
-- idempotência não usa nenhuma coluna nova em `events`: a própria
-- existência de uma notificação `event_review_open` com aquele
-- `event_id` no payload, para aquele usuário, já responde "já avisei
-- esse aí?" - reaproveita `notifications` como única fonte de verdade,
-- sem estado paralelo.
--
-- Mesmo padrão de extensão de CHECK já usado 2 vezes
-- (`20260720120045_alter_notifications_add_gamification_types.sql`,
-- `20260801130000_add_group_event_notifications.sql`).
alter table public.notifications drop constraint notifications_type_check;

alter table public.notifications add constraint notifications_type_check
  check (type in (
    'new_follower', 'new_comment', 'new_like', 'level_up', 'badge_earned',
    'group_member_joined', 'new_event', 'event_attendance_response',
    'event_review_open'
  ));

-- Escopada a `auth.uid()` (não recebe `p_group_id`) - de propósito:
-- chamada por um serviço central de sincronização lazy do usuário
-- autenticado (core/lazy_sync/), não por uma tela de um grupo
-- específico, então não há razão para depender de qual grupo o cliente
-- "estava olhando" no momento da chamada. Varre todos os rolês de TODOS
-- os grupos em que o usuário confirmou presença, exatamente como
-- `can_review_event()` (BLOCO 4) decide elegibilidade por rolê -
-- reaproveita a mesma regra (confirmado + `scheduled` + `scheduled_at`
-- já passada), sem duplicá-la.
create function public.notify_events_ready_for_review()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_caller_id uuid := auth.uid();
  v_event record;
  v_restaurant_name text;
begin
  if v_caller_id is null then
    return;
  end if;

  for v_event in
    select e.id, e.group_id, e.restaurant_id
    from public.events e
    join public.event_attendances ea
      on ea.event_id = e.id
    where ea.user_id = v_caller_id
      and ea.status = 'confirmed'
      and e.status = 'scheduled'
      and e.scheduled_at <= now()
      and not exists (
        select 1 from public.notifications n
        where n.user_id = v_caller_id
          and n.type = 'event_review_open'
          and n.payload->>'event_id' = e.id::text
      )
  loop
    select name into v_restaurant_name
    from public.restaurants where id = v_event.restaurant_id;

    -- create_notification() (DV-09, inalterada) - respeita
    -- notification_preferences (categoria 'groups', mesma das outras 3
    -- notificações de rolê) em vez de um INSERT direto na tabela.
    perform public.create_notification(
      v_caller_id,
      'event_review_open',
      'Avaliação liberada',
      'A avaliação coletiva de "' || coalesce(v_restaurant_name, 'restaurante') || '" já pode ser enviada.',
      jsonb_build_object('event_id', v_event.id, 'group_id', v_event.group_id),
      'groups'
    );
  end loop;
end;
$$;

-- GRANT explícito (mesma disciplina do resto do projeto) - sem isto, a
-- função é inalcançável mesmo com security definer.
revoke execute on function public.notify_events_ready_for_review() from public;
grant execute on function public.notify_events_ready_for_review() to authenticated;
