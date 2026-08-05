-- RC-03 Sprint 0 - Fechamento do motor social de Grupos/Rolês (F29 + F30)
--
-- Achado da RC-03 (RC03_PRODUCT_AUDIT.md/RC03_UX_AUDIT.md/RC03_FEATURE_GAP.md,
-- confirmado ao vivo em rc03_supabase_inventory.md §3a): confirmar presença
-- em rolê e enviar avaliação coletiva nunca concederam XP, diferente de
-- `reviews`/`comments`/`review_likes`, que já usam `award_gamification_points()`
-- desde `20260720120100_create_gamification_functions_and_triggers.sql`.
-- Esta migration reaproveita as duas funções centrais já existentes
-- (`award_gamification_points()`, `award_badge()`) sem alterá-las - nenhuma
-- função nova de gamificação é criada, só os triggers que faltavam.
--
-- Valores de XP (decisão registrada no RC03_IMPLEMENTATION_PLAN.md/relatório
-- da Sprint 0):
--  - event_reviews (avaliação coletiva) = 40/40, mesmo valor de `reviews`
--    (RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md §2: "avaliação coletiva passa a
--    gerar XP simetricamente" à avaliação individual).
--  - event_attendances confirmada = 20/20, sem ancoragem textual direta nos
--    documentos aprovados (nenhum valor foi fixado no PRD/Feature Gap) -
--    escolhido entre "comentar" (10) e "avaliar" (40) na escala já
--    estabelecida, proporcional ao esforço de confirmar presença.
--
-- F41 (notificação "avaliação liberada") NÃO está nesta migration - mesmo
-- bloqueio técnico já documentado em
-- `20260801130000_add_group_event_notifications.sql:9-17` (depende de
-- passagem de tempo, sem pg_cron/scheduler no projeto) - registrado como
-- decisão pendente no relatório da Sprint 0, não implementado
-- silenciosamente como outra coisa.

-- event_attendances: credita quem confirmou presença. Mesmo formato de
-- `WHEN` de `notify_event_attendance_response_trigger` (só reage a
-- transições reais de status, não ao fan-out inicial de `create_event()`
-- que insere 'pending' para todo mundo) - mas escopado só a 'confirmed'
-- (recusar não gera XP). Mesmo nível de tolerância a "re-toggle" que já
-- existe hoje em `review_likes` (curtir/descurtir/curtir soma XP de novo) -
-- não introduz uma disciplina de idempotência mais rígida do que o resto
-- da base já usa.
create function public.handle_gamification_new_attendance()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_confirmed_count integer;
begin
  perform public.award_gamification_points(new.user_id, 20, 20);

  select count(*) into v_confirmed_count
  from public.event_attendances
  where user_id = new.user_id and status = 'confirmed';

  if v_confirmed_count >= 5 then
    perform public.award_badge(new.user_id, 'presenca_consistente');
  end if;

  return new;
end;
$$;

create trigger handle_gamification_new_attendance_trigger
  after update on public.event_attendances
  for each row
  when (new.status is distinct from old.status and new.status = 'confirmed')
  execute procedure public.handle_gamification_new_attendance();

-- event_reviews: credita quem avaliou coletivamente - mesmo valor (40/40)
-- e mesmo formato de `reviews` (DV-10), simétrico por decisão do PRD.
-- INSERT-only, como `reviews` - `event_reviews_unique(event_id, user_id)`
-- já impede reenvio duplicado pela própria constraint de banco, sem risco
-- de farming equivalente ao de `event_attendances` acima.
create function public.handle_gamification_new_event_review()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  perform public.award_gamification_points(new.user_id, 40, 40);
  return new;
end;
$$;

create trigger handle_gamification_new_event_review_trigger
  after insert on public.event_reviews
  for each row execute procedure public.handle_gamification_new_event_review();

-- Badge novo (F30) - único citado como exemplo no RC03_FEATURE_GAP.md §5.11
-- ("presença consistente"), sem outros badges adicionados além deste.
insert into public.badges (code, name, description) values
  ('presenca_consistente', 'Presença Consistente', 'Confirmou presença em 5 rolês.');
