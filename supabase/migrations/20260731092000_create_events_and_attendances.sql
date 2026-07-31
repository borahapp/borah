-- ROLE-01 - Roles (encontros presenciais de um grupo)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente. Sera
-- validada contra Postgres 16 puro (schema auth/storage simulado) antes
-- do commit - ver relatorio da rodada ROLE-01, mesmo procedimento do
-- GROUP-01.
--
-- Hipotese de produto registrada nesta rodada: "Um grupo organizou um
-- role quando existe um evento com grupo, restaurante, data e pelo
-- menos um participante confirmado." Essa condicao ja fica satisfeita
-- no instante da criacao (o organizador entra confirmado
-- automaticamente, ver create_event() abaixo) - a metrica pode ser
-- lida a partir da criacao, sem depender de ninguem confirmar depois.
--
-- Ressurreicao parcial do escopo de `docs/FASE 2 - Documentacao/
-- ET-06_EVENTS.md` (nunca migrado) - nomes de tabela em ingles
-- (`events`/`event_attendances`), nao "roles", para nao colidir
-- conceitualmente com `CREATE ROLE`/`pg_roles` do proprio Postgres nem
-- com a coluna `group_members.role` ja existente. "Role" continua sendo
-- só o vocabulário de marca/PT-BR, não um nome de tabela.
--
-- `scheduled_at` representa apenas o horario PLANEJADO do role. O MVP
-- nao diferencia horario planejado de horario real (nao ha check-in
-- nem "hora que de fato aconteceu") - essa distincao fica para uma
-- rodada futura, se vier a ser necessaria (ex.: modulo de Memorias/
-- Estatisticas).
--
-- `organizer_id` e mantido só como registro historico (quem criou o
-- role) - NAO concede nenhum privilegio especial. Toda permissao de
-- update/delete usa exclusivamente os papeis do grupo (`is_group_admin`/
-- `is_group_owner`, GROUP-01), nunca `organizer_id = auth.uid()`. Mesmo
-- papel de `restaurants.created_by`/`audit_logs.actor_id` - dado, nao
-- permissao.

create table public.events (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  restaurant_id uuid not null references public.restaurants (id) on delete restrict,
  organizer_id uuid not null references auth.users (id) on delete restrict,
  scheduled_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index events_group_id_idx on public.events (group_id);

-- Reutiliza a funcao compartilhada de 20260718212615_add_set_updated_at_function.sql
-- - nao recriar essa logica aqui.
create trigger set_events_updated_at
  before update on public.events
  for each row execute procedure public.set_updated_at();

-- `pending` (nao `invited`): create_event() abaixo ja insere uma linha
-- de presenca para cada membro atual do grupo no momento da criacao
-- (fan-out atomico, mesma logica de create_group() inserir o owner) -
-- a linha ja existe fisicamente a espera de resposta, entao "aguardando
-- resposta" descreve o estado com mais precisao do que "convidado"
-- (que sugeriria uma acao de convite separada, inexistente aqui).
create table public.event_attendances (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'declined')),
  created_at timestamptz not null default now(),

  constraint event_attendances_unique unique (event_id, user_id)
);

-- `(event_id, user_id)` unique acima ja cobre "presencas de um evento"
-- (event_id lider do indice). Os dois casos que precisam de indice
-- proprio: "todos os roles que um usuario participa" e "contagem de
-- confirmados/pendentes/recusados de um evento" (ex.: "4 confirmados"
-- na tela de detalhe do role, ROLE-02+).
create index event_attendances_user_id_idx on public.event_attendances (user_id);
create index event_attendances_event_status_idx on public.event_attendances (event_id, status);

-- Funcao auxiliar para RLS de `event_attendances` - `events` reaproveita
-- `is_group_member`/`is_group_admin` (GROUP-01) diretamente, porque tem
-- `group_id` como coluna propria; `event_attendances` so tem `event_id`,
-- entao precisa de um helper dedicado. `security definer` obrigatorio -
-- mesmo motivo do "Bug 3" ja catalogado no projeto (evita reavaliar RLS
-- de `events`/`group_members` dentro da propria checagem).
--
-- Nome mantido como `is_event_group_member` (nao renomeado para
-- `can_access_event`): as 3 funcoes analogas do projeto
-- (`is_group_member`/`is_group_admin`/`is_group_owner`) sao todas
-- verificacoes de estado com prefixo `is_`, usadas direto em `using()`
-- de RLS - esse e o padrao dominante (3 ocorrencias). `can_moderate`
-- (unica funcao `can_*` do projeto) e uma capacidade que abrange varias
-- policies/tabelas diferentes - um caso distinto, nao o padrao a seguir
-- aqui. Um nome `can_access_event` tambem seria menos preciso: nao diz
-- que a checagem e derivada de membership de grupo (o que
-- `is_event_group_member` deixa explicito, como as demais).
create function public.is_event_group_member(uid uuid, eid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.events e
    join public.group_members gm on gm.group_id = e.group_id
    where e.id = eid and gm.user_id = uid
  );
$$;

alter table public.events enable row level security;
alter table public.event_attendances enable row level security;

create policy "events_select_members"
  on public.events for select
  to authenticated
  using (public.is_group_member(auth.uid(), group_id));

-- INSERT bloqueado direto - so via create_event() (fan-out atomico de
-- evento + presencas, ver abaixo).
create policy "events_insert_blocked"
  on public.events for insert
  to authenticated
  with check (false);

-- UPDATE (cancelar/reagendar): so admin/owner do grupo -
-- `organizer_id` nunca entra nessa checagem (ver nota acima).
create policy "events_update_admin"
  on public.events for update
  to authenticated
  using (public.is_group_admin(auth.uid(), group_id))
  with check (public.is_group_admin(auth.uid(), group_id));

-- Sem policy de DELETE: cancelamento e status='cancelled' (update), nao
-- remocao de linha - preserva o historico para o futuro modulo de
-- Memorias/Estatisticas.

create policy "event_attendances_select_members"
  on public.event_attendances for select
  to authenticated
  using (public.is_event_group_member(auth.uid(), event_id));

-- INSERT bloqueado direto - so via create_event() (fan-out).
create policy "event_attendances_insert_blocked"
  on public.event_attendances for insert
  to authenticated
  with check (false);

-- UPDATE: o proprio membro responde (pending -> confirmed/declined).
create policy "event_attendances_update_own"
  on public.event_attendances for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- create_event(): cria o evento e a presenca de cada membro atual do
-- grupo na mesma transacao (organizador = confirmed, demais = pending)
-- - mesmo padrao atomico de create_group() inserir o owner. Tambem
-- atualiza `groups.last_activity_at` na mesma transacao (RN desta
-- rodada) - criar um role e, por definicao, atividade do grupo.
create function public.create_event(
  p_group_id uuid,
  p_restaurant_id uuid,
  p_scheduled_at timestamptz
)
returns public.events
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_event public.events;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if not public.is_group_member(v_user_id, p_group_id) then
    raise exception 'Você não é membro deste grupo.';
  end if;

  insert into public.events (group_id, restaurant_id, organizer_id, scheduled_at)
  values (p_group_id, p_restaurant_id, v_user_id, p_scheduled_at)
  returning * into v_event;

  insert into public.event_attendances (event_id, user_id, status)
  select
    v_event.id,
    gm.user_id,
    case when gm.user_id = v_user_id then 'confirmed' else 'pending' end
  from public.group_members gm
  where gm.group_id = p_group_id;

  update public.groups
  set last_activity_at = now()
  where id = p_group_id;

  return v_event;
end;
$$;

-- GRANT explicito (mesma disciplina de GROUP-01). Sem `insert` em
-- nenhuma das duas tabelas - toda criacao passa por create_event().
-- Sem `delete` em nenhuma das duas - cancelamento e update de status,
-- e presencas nunca sao removidas (so atualizadas).
grant select, update on public.events to authenticated;
grant select, update on public.event_attendances to authenticated;

revoke execute on function public.create_event(uuid, uuid, timestamptz) from public;
grant execute on function public.create_event(uuid, uuid, timestamptz) to authenticated;

-- is_event_group_member: sem REVOKE/GRANT explicito - mesmo padrao de
-- is_group_member/is_group_admin/is_group_owner (GROUP-01) e
-- is_admin/has_admin_role/can_moderate (user_roles.sql), todas funcoes
-- de leitura booleana usadas dentro de policies, sem grant proprio.
