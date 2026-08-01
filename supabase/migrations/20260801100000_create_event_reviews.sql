-- BLOCO 4 - Avaliação Coletiva (event_reviews)
--
-- Ressurreicao parcial do escopo de `docs/FASE 2 - Documentacao/
-- ET-08_REVIEWS_AND_RANKINGS.md` (nunca migrado como especificado -
-- DV-04 optou deliberadamente por avaliacao por restaurante, nao por
-- evento, ver comentario de `20260718230512_create_reviews.sql`). Os 5
-- criterios abaixo (comida/atendimento/ambiente/custo-beneficio/
-- experiencia geral) sao um subconjunto deliberado dos 8 do ET-08
-- (sem bebidas/musica/tempo de espera/limpeza) - escopo exato pedido
-- nesta rodada, nao um esquecimento. Sem check-in (RN-001 do ET-08) -
-- esse conceito nunca foi implementado no projeto (ROLE-01/03
-- deliberadamente nao o adicionaram); a elegibilidade usa
-- `event_attendances.status = 'confirmed'` como substituto.
--
-- Tabela separada de `reviews` (nao reaproveitada) - `reviews` e sobre
-- avaliar um restaurante para o catalogo publico do app (DV-04,
-- `reviews_select_authenticated` usa `using(true)`); `event_reviews` e
-- sobre o grupo avaliar coletivamente UM rolê especifico, visivel só
-- para membros do grupo (`is_event_group_member`). Misturar as duas
-- tabelas juntaria dois publicos e duas políticas de RLS incompatíveis
-- numa só - `restaurants.average_rating`/`total_reviews` (publico,
-- alimentado só por `reviews`) NUNCA e tocado por esta migration.

create table public.event_reviews (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  -- `on delete cascade` (nao `restrict` como `reviews.user_id`) -
  -- decisao deliberada: uma avaliacao coletiva de rolê e um registro de
  -- participacao (mesmo papel de `event_attendances.user_id`/
  -- `group_members.user_id`, ambos cascade), nao conteudo publico
  -- atribuido a um autor (papel de `reviews.user_id`, que por isso e
  -- preservado via `delete_own_account()` reatribuindo a um
  -- placeholder). Cascade aqui evita precisar de uma migration
  -- companheira de `delete_own_account()` - o agregado do evento
  -- (`recalculate_event_rating` abaixo) recalcula sozinho, sem a
  -- avaliacao de quem saiu.
  user_id uuid not null references auth.users (id) on delete cascade,
  food_score numeric(2, 1) not null check (food_score between 1 and 5),
  service_score numeric(2, 1) not null check (service_score between 1 and 5),
  ambience_score numeric(2, 1) not null check (ambience_score between 1 and 5),
  cost_benefit_score numeric(2, 1) not null check (cost_benefit_score between 1 and 5),
  overall_score numeric(2, 1) not null check (overall_score between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint event_reviews_unique unique (event_id, user_id)
);

-- `unique(event_id, user_id)` acima já cobre "avaliações de um evento"
-- (event_id líder do índice) - sem índice redundante. Sem índice por
-- `user_id` isolado - nenhuma tela desta rodada lista "minhas
-- avaliações entre eventos", só o agregado por evento.

-- Agregado denormalizado em `events`, mesmo padrão de
-- `restaurants.average_rating`/`total_reviews` (DV-04) - "nota final"
-- e "média ponderada" (do pedido original) colapsam no mesmo número
-- aqui: sem um esquema de pesos por critério especificado, a média
-- simples dos 5 critérios já É a média ponderada com pesos iguais:
-- decisão registrada, não esquecimento - trivial de mudar para pesos
-- reais no futuro (só a expressão do `avg()` abaixo mudaria).
alter table public.events add column average_rating numeric;
alter table public.events add column total_reviews integer not null default 0;

create trigger set_event_reviews_updated_at
  before update on public.event_reviews
  for each row execute procedure public.set_updated_at();

-- Elegibilidade para avaliar (RN desta rodada, substituto de check-in):
-- só quem confirmou presença, e só depois que o rolê de fato aconteceu
-- (data já passada) e não foi cancelado. `security definer` pelo mesmo
-- motivo de `is_event_group_member` (ROLE-01) - evita reavaliar RLS de
-- `events`/`event_attendances` dentro da própria checagem.
create function public.can_review_event(uid uuid, eid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.events e
    join public.event_attendances ea on ea.event_id = e.id
    where e.id = eid
      and ea.user_id = uid
      and ea.status = 'confirmed'
      and e.status = 'scheduled'
      and e.scheduled_at <= now()
  );
$$;

alter table public.event_reviews enable row level security;

create policy "event_reviews_select_members"
  on public.event_reviews for select
  to authenticated
  using (public.is_event_group_member(auth.uid(), event_id));

create policy "event_reviews_insert_own"
  on public.event_reviews for insert
  to authenticated
  with check (auth.uid() = user_id and public.can_review_event(auth.uid(), event_id));

-- UPDATE (editar a própria avaliação): sem reverificar
-- `can_review_event` - se já era elegível para criar, continua podendo
-- ajustar o que já escreveu, mesmo padrão de `reviews_update_own`
-- (DV-04, que também não reverifica nada no UPDATE).
create policy "event_reviews_update_own"
  on public.event_reviews for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Sem policy de DELETE - mesma decisão de `reviews` (DV-04): nenhuma
-- exclusão física nesta etapa.

-- Recalcula `events.average_rating`/`total_reviews` a cada mudança em
-- `event_reviews` - mesmo padrão de `recalculate_restaurant_rating`
-- (DV-04), recalculando do zero em vez de incrementar/decrementar.
--
-- SECURITY DEFINER É OBRIGATÓRIO aqui, não opcional - este projeto já
-- teve exatamente este bug (`20260720130015_fix_recalculate_triggers_
-- security_definer.sql`, "Bug 2"): sem isso, o UPDATE interno em
-- `events` roda com o privilégio de quem inseriu/alterou a *própria*
-- avaliação, sujeito à RLS de `events` (`events_update_admin`, só
-- admin/owner) - como quem avalia quase nunca é admin/owner do grupo,
-- o recálculo seria silenciosamente filtrado (0 linhas afetadas, sem
-- erro), exatamente como aconteceu com `restaurants.average_rating`
-- antes da correção. Não repetir o mesmo bug aqui.
create function public.recalculate_event_rating()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  affected_event_id uuid;
begin
  affected_event_id := coalesce(new.event_id, old.event_id);

  update public.events
  set
    average_rating = (
      select avg((food_score + service_score + ambience_score + cost_benefit_score + overall_score) / 5)
      from public.event_reviews
      where event_id = affected_event_id
    ),
    total_reviews = (
      select count(*) from public.event_reviews
      where event_id = affected_event_id
    )
  where id = affected_event_id;

  return coalesce(new, old);
end;
$$;

create trigger recalculate_event_rating_on_review_change
  after insert or update or delete on public.event_reviews
  for each row execute procedure public.recalculate_event_rating();

-- GRANT explicito (mesma disciplina do resto do projeto). Sem `delete`
-- - mesma decisão de `reviews` (DV-04).
grant select, insert, update on public.event_reviews to authenticated;

-- can_review_event: sem REVOKE/GRANT explícito - mesmo padrão de
-- is_event_group_member/is_group_member (funções de leitura booleana
-- usadas dentro de policies, sem grant próprio).
