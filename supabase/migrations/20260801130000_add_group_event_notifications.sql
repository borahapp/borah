-- BLOCO 8 - Notificações essenciais (convite aceito, novo rolê, confirmação)
--
-- Mesmo padrão já em produção desde o DV-09
-- (`20260720100030_create_notification_triggers.sql`): gerado via
-- trigger Postgres (não Edge Function), reaproveitando
-- `create_notification()` tal como está - nenhuma mudança na função
-- compartilhada, só 3 triggers novos que a chamam.
--
-- "Avaliação liberada" (4º item do pedido original) NÃO está nesta
-- migration - ela dependeria de um evento que não existe no Postgres
-- (a passagem do tempo até `scheduled_at`, sem nenhum job agendado no
-- projeto - confirmado: nenhuma extensão `pg_cron` instalada, nenhuma
-- infraestrutura de scheduler). Diferente dos outros 3 itens (que são
-- reações a um INSERT/UPDATE real), "avaliação liberada" precisaria de
-- uma decisão de infraestrutura própria (`pg_cron` rodando a cada N
-- minutos, ou um Edge Function agendado) - registrado como bloqueio
-- técnico real, não implementado silenciosamente como outra coisa.

-- Categoria própria para Grupos/Rolês - "social" (DV-09) modela
-- especificamente o grafo de seguidores (ET-09/DV-07), um modelo social
-- diferente e concorrente do de grupos fechados (já discutido na
-- auditoria MVP-INTEGRATION-01); tratar convite/rolê/confirmação como
-- "social" misturaria as duas categorias de notificação. Mesmo padrão
-- de extensão já usado para o DV-10 (`20260720120045_alter_
-- notifications_add_gamification_types.sql`).
alter table public.notification_preferences drop constraint notification_preferences_category_check;

alter table public.notification_preferences add constraint notification_preferences_category_check
  check (category in ('social', 'restaurants', 'reviews', 'system', 'gamification', 'groups'));

alter table public.notifications drop constraint notifications_type_check;

alter table public.notifications add constraint notifications_type_check
  check (type in (
    'new_follower', 'new_comment', 'new_like', 'level_up', 'badge_earned',
    'group_member_joined', 'new_event', 'event_attendance_response'
  ));

-- group_members: notifica o owner quando alguém entra no grupo. Exclui
-- `role = 'owner'` explicitamente - sem isso, `create_group()` também
-- dispararia esta trigger para o próprio criador na mesma transação
-- (o INSERT do owner em `group_members` é idêntico ao de um member
-- comum, só o `role` distingue).
create function public.notify_group_member_joined()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_owner_id uuid;
  v_group_name text;
begin
  if new.role = 'owner' then
    return new;
  end if;

  select owner_id, name into v_owner_id, v_group_name
  from public.groups
  where id = new.group_id;

  if v_owner_id is null or v_owner_id = new.user_id then
    return new;
  end if;

  perform public.create_notification(
    v_owner_id,
    'group_member_joined',
    'Novo membro',
    'Alguém entrou no grupo "' || v_group_name || '".',
    jsonb_build_object('group_id', new.group_id, 'user_id', new.user_id),
    'groups'
  );
  return new;
end;
$$;

create trigger notify_group_member_joined_trigger
  after insert on public.group_members
  for each row execute procedure public.notify_group_member_joined();

-- events: notifica todo membro do grupo, exceto o organizador (que já
-- sabe - foi ele que criou). Único trigger com fan-out (várias
-- notificações por evento) - mesmo raciocínio de `create_event()`
-- inserir uma linha de presença por membro, mas para `notifications`
-- em vez de `event_attendances`.
create function public.notify_new_event()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_restaurant_name text;
  v_member record;
begin
  select name into v_restaurant_name
  from public.restaurants
  where id = new.restaurant_id;

  for v_member in
    select user_id from public.group_members
    where group_id = new.group_id and user_id <> new.organizer_id
  loop
    perform public.create_notification(
      v_member.user_id,
      'new_event',
      'Novo rolê',
      'Um novo rolê foi criado: ' || coalesce(v_restaurant_name, 'restaurante'),
      jsonb_build_object('event_id', new.id, 'group_id', new.group_id),
      'groups'
    );
  end loop;

  return new;
end;
$$;

create trigger notify_new_event_trigger
  after insert on public.events
  for each row execute procedure public.notify_new_event();

-- event_attendances: notifica o organizador do rolê quando outra
-- pessoa confirma ou recusa presença - o `when` na trigger só dispara
-- em transições reais de status (não no fan-out inicial do
-- `create_event()`, que insere `pending` para todo mundo de uma vez).
create function public.notify_event_attendance_response()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_organizer_id uuid;
  v_group_id uuid;
  v_responder_name text;
  v_status_label text;
begin
  select organizer_id, group_id into v_organizer_id, v_group_id
  from public.events
  where id = new.event_id;

  if v_organizer_id is null or v_organizer_id = new.user_id then
    return new;
  end if;

  select full_name into v_responder_name
  from public.profiles
  where id = new.user_id;

  v_status_label := case new.status when 'confirmed' then 'confirmou' else 'recusou' end;

  perform public.create_notification(
    v_organizer_id,
    'event_attendance_response',
    'Resposta ao rolê',
    coalesce(v_responder_name, 'Alguém') || ' ' || v_status_label || ' presença.',
    -- `group_id` no payload (não só `event_id`) - a tela de detalhe do
    -- rolê exige os dois na rota (`/groups/:groupId/events/:eventId`,
    -- ROLÊ-01) - sem isso, `NotificationDetailPage` não teria como
    -- navegar até lá.
    jsonb_build_object(
      'event_id', new.event_id,
      'group_id', v_group_id,
      'user_id', new.user_id,
      'status', new.status
    ),
    'groups'
  );
  return new;
end;
$$;

create trigger notify_event_attendance_response_trigger
  after update on public.event_attendances
  for each row
  when (new.status is distinct from old.status and new.status in ('confirmed', 'declined'))
  execute procedure public.notify_event_attendance_response();
