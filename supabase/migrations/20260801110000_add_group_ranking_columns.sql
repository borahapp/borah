-- BLOCO 5 - Ranking do Grupo
--
-- Critério escolhido entre os "exemplos" registrados no pedido original
-- (participação/organização/avaliação/sequência) - "quantidade de
-- rolês" (participação, via presença confirmada) como critério
-- primário de ordenação, "quantidade de avaliações" e "média" (nota
-- média que o PRÓPRIO usuário deu em suas avaliações, não a nota dos
-- restaurantes que organizou) como critérios secundários exibidos.
-- "Quem organizou mais encontros"/"quem sugeriu restaurantes mais bem
-- avaliados"/"confirmou mais rápido"/"maior sequência de presença"
-- ficam registrados como critérios futuros (o pedido original os lista
-- como "exemplos", não uma fórmula obrigatória) - "confirmou mais
-- rápido" e "sequência" exigiriam uma coluna de timestamp que
-- `event_attendances` não tem hoje (`created_at` é quando a linha foi
-- criada pelo fan-out de `create_event()`, não quando o membro
-- respondeu) - fora do escopo desta rodada.
--
-- Arquitetura: mesmo padrão já usado por TODO ranking existente no
-- projeto (restaurants.average_rating/total_reviews - DV-04;
-- user_progress.points - DV-10) - coluna denormalizada em
-- `group_members`, mantida por trigger, consultada com `order by`
-- direto. Nenhuma função de agregação "GROUP BY" nova - confirmado por
-- busca que esse padrão nunca existiu no projeto (todo `count`/`avg`
-- em função é um subquery escopado a UMA linha do lado que disparou o
-- trigger, nunca um relatório agregando várias linhas de saída).

alter table public.group_members add column events_count integer not null default 0;
alter table public.group_members add column reviews_count integer not null default 0;
alter table public.group_members add column average_score numeric;

-- Recalcula `events_count` (rolês com presença confirmada, dentro do
-- grupo) a cada mudança em `event_attendances`. SECURITY DEFINER
-- obrigatório - `group_members` não tem policy de "UPDATE da própria
-- linha" (só `group_members_update_owner`, restrita ao owner para
-- promover/rebaixar, GROUP-01) - sem isso, um membro comum confirmando
-- a própria presença não conseguiria atualizar sua própria contagem,
-- mesmo bug já catalogado (`20260720130015_fix_recalculate_triggers_
-- security_definer.sql`, "Bug 2").
create function public.recalculate_member_events_count()
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
  set events_count = (
    select count(*)
    from public.event_attendances ea
    join public.events e on e.id = ea.event_id
    where e.group_id = affected_group_id
      and ea.user_id = affected_user_id
      and ea.status = 'confirmed'
  )
  where group_id = affected_group_id and user_id = affected_user_id;

  return coalesce(new, old);
end;
$$;

create trigger recalculate_member_events_count_on_attendance_change
  after insert or update or delete on public.event_attendances
  for each row execute procedure public.recalculate_member_events_count();

-- Recalcula `reviews_count`/`average_score` (nota média que o PRÓPRIO
-- usuário deu, não a dos restaurantes que organizou) a cada mudança em
-- `event_reviews`. Mesmo motivo de SECURITY DEFINER acima.
create function public.recalculate_member_review_stats()
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
    reviews_count = (
      select count(*)
      from public.event_reviews er
      join public.events e on e.id = er.event_id
      where e.group_id = affected_group_id and er.user_id = affected_user_id
    ),
    average_score = (
      select avg((food_score + service_score + ambience_score + cost_benefit_score + overall_score) / 5)
      from public.event_reviews er
      join public.events e on e.id = er.event_id
      where e.group_id = affected_group_id and er.user_id = affected_user_id
    )
  where group_id = affected_group_id and user_id = affected_user_id;

  return coalesce(new, old);
end;
$$;

create trigger recalculate_member_review_stats_on_review_change
  after insert or update or delete on public.event_reviews
  for each row execute procedure public.recalculate_member_review_stats();

-- Sem índice novo em `group_members` para a ordenação do ranking -
-- mesma decisão de `restaurants`/`user_progress` (nenhum dos dois tem
-- índice dedicado à própria coluna de ranking; grupos/tabelas de
-- ranking deste projeto são pequenos o suficiente para um sort em
-- memória, confirmado pelo padrão já em produção).
