-- DV-09 - Notifications Module (geracao via trigger)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Geracao de notificacoes via trigger Postgres, NAO via Edge Function
-- (decisao 1 do DV-09 - mesmo raciocinio do recalculate_restaurant_rating
-- do DV-04/DV-05). create_notification() e compartilhada pelos 3
-- triggers abaixo; retorna imediatamente se o destinatario for nulo
-- (decisao 2) ou se a preferencia 'social' estiver desativada.

create function public.create_notification(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_message text,
  p_payload jsonb default null,
  p_category text default 'social'
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_enabled boolean;
begin
  if p_user_id is null then
    return;
  end if;

  select in_app_enabled into v_enabled
  from public.notification_preferences
  where user_id = p_user_id and category = p_category;

  if v_enabled is false then
    return;
  end if;

  insert into public.notifications (user_id, type, title, message, payload)
  values (p_user_id, p_type, p_title, p_message, p_payload);
end;
$$;

-- followers: notifica quem passou a ser seguido.
create function public.notify_new_follower()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  perform public.create_notification(
    new.following_id,
    'new_follower',
    'Novo seguidor',
    'Alguém começou a seguir você.',
    jsonb_build_object('follower_id', new.follower_id)
  );
  return new;
end;
$$;

create trigger notify_new_follower_trigger
  after insert on public.followers
  for each row execute procedure public.notify_new_follower();

-- comments: notifica o autor da avaliação, exceto se ele comentou na
-- própria avaliação.
create function public.notify_new_comment()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_review_user_id uuid;
begin
  select user_id into v_review_user_id
  from public.reviews
  where id = new.review_id;

  if v_review_user_id is null or v_review_user_id = new.user_id then
    return new;
  end if;

  perform public.create_notification(
    v_review_user_id,
    'new_comment',
    'Novo comentário',
    'Alguém comentou na sua avaliação.',
    jsonb_build_object('review_id', new.review_id, 'comment_id', new.id)
  );
  return new;
end;
$$;

create trigger notify_new_comment_trigger
  after insert on public.comments
  for each row execute procedure public.notify_new_comment();

-- review_likes: notifica o autor da avaliação, exceto se ele curtiu a
-- própria avaliação.
create function public.notify_new_like()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_review_user_id uuid;
begin
  select user_id into v_review_user_id
  from public.reviews
  where id = new.review_id;

  if v_review_user_id is null or v_review_user_id = new.user_id then
    return new;
  end if;

  perform public.create_notification(
    v_review_user_id,
    'new_like',
    'Nova curtida',
    'Alguém curtiu sua avaliação.',
    jsonb_build_object('review_id', new.review_id, 'liked_by', new.user_id)
  );
  return new;
end;
$$;

create trigger notify_new_like_trigger
  after insert on public.review_likes
  for each row execute procedure public.notify_new_like();
