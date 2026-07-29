-- DV-10 - Gamification Module (motor de pontuacao e badges)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Geracao via trigger Postgres, NAO via Edge Function (mesmo raciocinio
-- do DV-09). Valores de XP/Points por evento (decisao do DV-10):
-- avaliar = 40/40, comentar = 10/10, receber curtida = 5/5. Niveis
-- oficiais da v1.0: 1=0XP, 2=200XP, 3=500XP, 4=900XP (ET-13 deixou de ser
-- exemplo). Sem reversao de XP/badges em exclusoes (decisao 5 do DV-10).

-- award_badge(): concede um badge no maximo uma vez via
-- INSERT ... ON CONFLICT DO NOTHING (decisao 3 do DV-10 - sem consulta
-- previa de existencia). RETURNING indica se a linha foi de fato
-- inserida; a notificacao so e gerada nesse caso.
create function public.award_badge(p_user_id uuid, p_badge_code text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_badge_id uuid;
  v_badge_name text;
  v_inserted_id uuid;
begin
  select id, name into v_badge_id, v_badge_name
  from public.badges
  where code = p_badge_code;

  if v_badge_id is null then
    return;
  end if;

  insert into public.user_badges (user_id, badge_id)
  values (p_user_id, v_badge_id)
  on conflict (user_id, badge_id) do nothing
  returning id into v_inserted_id;

  if v_inserted_id is null then
    return;
  end if;

  perform public.create_notification(
    p_user_id,
    'badge_earned',
    'Nova conquista!',
    'Você desbloqueou o badge "' || v_badge_name || '".',
    jsonb_build_object('badge_id', v_badge_id, 'badge_code', p_badge_code),
    'gamification'
  );
end;
$$;

-- award_gamification_points(): sequencia decidida no DV-10 -
-- (1) atualizar XP/Points, (2) recalcular nivel, (3) verificar badges,
-- (4) gerar notificacoes quando aplicavel.
create function public.award_gamification_points(
  p_user_id uuid,
  p_xp integer,
  p_points integer
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_old_level integer;
  v_new_xp integer;
  v_new_level integer;
begin
  select level into v_old_level from public.user_progress where user_id = p_user_id;

  -- (1) Atualizar XP/Points
  insert into public.user_progress (user_id, xp, points, level)
  values (p_user_id, p_xp, p_points, 1)
  on conflict (user_id) do update
    set xp = public.user_progress.xp + excluded.xp,
        points = public.user_progress.points + excluded.points,
        updated_at = now()
  returning xp into v_new_xp;

  -- (2) Recalcular nivel (limiares oficiais da v1.0)
  v_new_level := case
    when v_new_xp >= 900 then 4
    when v_new_xp >= 500 then 3
    when v_new_xp >= 200 then 2
    else 1
  end;

  update public.user_progress set level = v_new_level where user_id = p_user_id;

  -- (3) Verificar badges (baseados em XP - os baseados em contagem de
  -- avaliacoes/curtidas ficam nos triggers especificos abaixo)
  if v_new_xp >= 500 then
    perform public.award_badge(p_user_id, 'gourmet');
  end if;

  -- (4) Gerar notificacoes quando aplicavel
  if v_old_level is not null and v_new_level > v_old_level then
    perform public.create_notification(
      p_user_id,
      'level_up',
      'Novo nível!',
      'Você alcançou o nível ' || v_new_level || '.',
      jsonb_build_object('level', v_new_level),
      'gamification'
    );
  end if;
end;
$$;

-- reviews: credita quem avaliou; verifica badges por contagem de
-- avaliacoes/restaurantes distintos.
create function public.handle_gamification_new_review()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_review_count integer;
  v_distinct_restaurants integer;
begin
  perform public.award_gamification_points(new.user_id, 40, 40);

  select count(*) into v_review_count
  from public.reviews
  where user_id = new.user_id and deleted_at is null;

  if v_review_count = 1 then
    perform public.award_badge(new.user_id, 'first_review');
  end if;

  if v_review_count >= 25 then
    perform public.award_badge(new.user_id, 'critico');
  end if;

  select count(distinct restaurant_id) into v_distinct_restaurants
  from public.reviews
  where user_id = new.user_id and deleted_at is null;

  if v_distinct_restaurants >= 10 then
    perform public.award_badge(new.user_id, 'explorador');
  end if;

  return new;
end;
$$;

create trigger handle_gamification_new_review_trigger
  after insert on public.reviews
  for each row execute procedure public.handle_gamification_new_review();

-- comments: credita quem comentou.
create function public.handle_gamification_new_comment()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  perform public.award_gamification_points(new.user_id, 10, 10);
  return new;
end;
$$;

create trigger handle_gamification_new_comment_trigger
  after insert on public.comments
  for each row execute procedure public.handle_gamification_new_comment();

-- review_likes: credita o autor da avaliacao curtida (nao quem curtiu).
-- Autocurtida (curtir a propria avaliacao) NAO gera XP, badge nem
-- notificacao (decisao 4 do DV-10) - retorna antes de qualquer efeito.
create function public.handle_gamification_new_like()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_review_user_id uuid;
  v_likes_received integer;
begin
  select user_id into v_review_user_id
  from public.reviews
  where id = new.review_id;

  if v_review_user_id is null or v_review_user_id = new.user_id then
    return new;
  end if;

  perform public.award_gamification_points(v_review_user_id, 5, 5);

  select count(*) into v_likes_received
  from public.review_likes rl
  join public.reviews r on r.id = rl.review_id
  where r.user_id = v_review_user_id;

  if v_likes_received >= 50 then
    perform public.award_badge(v_review_user_id, 'influenciador');
  end if;

  return new;
end;
$$;

create trigger handle_gamification_new_like_trigger
  after insert on public.review_likes
  for each row execute procedure public.handle_gamification_new_like();
