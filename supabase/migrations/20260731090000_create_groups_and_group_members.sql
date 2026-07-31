-- GROUP-01 - Grupos Fechados (groups/group_members)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B). Foi validada, sim, contra
-- Postgres 16 puro (com um schema `auth`/`storage` simulado) - ver relatorio
-- da rodada GROUP-01 para as 32 migrations + 17 cenarios funcionais
-- confirmados.
--
-- PENDENCIA DE VERIFICACAO POS-DEPLOY (nao verificavel sem acesso a um
-- projeto Supabase real, fora do escopo desta sessao): confirmar que as
-- funcoes `security definer` abaixo (generate_group_invite_code,
-- is_group_member/is_group_admin/is_group_owner, create_group,
-- join_group_by_invite_code, regenerate_group_invite_code) sao criadas
-- com o owner esperado pelo pipeline real de deploy (`postgres` ou
-- `supabase_admin`, o que o `supabase db push`/Dashboard usar) - o owner
-- de uma funcao `security definer` e quem determina com qual privilegio
-- ela roda; se o CLI/Dashboard rodar a migration com um role sem
-- privilegio de bypass de RLS, as funcoes nao vao funcionar como
-- desenhado apesar do `security definer` presente no codigo. Verificar
-- com `select proname, proowner::regrole from pg_proc where proname in
-- ('create_group', 'join_group_by_invite_code', ...);` apos o primeiro
-- deploy real.
--
-- Ressurreicao de escopo ja especificado em `docs/FASE 2 - Documentacao/
-- ET-05_GROUPS.md`, nunca migrado - decisao de reposicionamento de produto
-- registrada nesta rodada (BORAH como "o ranking dos seus roles", nao mais
-- "app de reviews individuais"). Grupo fechado e a unidade principal;
-- `followers`/`favorites`/ranking global (DV-04/05/07) permanecem como
-- estao, sem alteracao - nada e removido desta rodada, apenas adicionado.
--
-- Papeis usam `text + check` (nao ENUM) - decisao deliberada de manter o
-- mesmo padrao usado em `user_roles.role`, `restaurants.status`,
-- `notifications.type`, `feedback.status`, `beta_waitlist.status`: nenhuma
-- migration do projeto usa ENUM ate hoje, e adicionar um novo papel no
-- futuro via ALTER TYPE e mais rigido que soltar/recriar um CHECK. A
-- legibilidade das policies vem das funcoes is_group_owner/is_group_admin/
-- is_group_member abaixo, nao do tipo da coluna.
--
-- `group_members` usa `id uuid` surrogate + `unique(group_id, user_id)`,
-- nao PK composta - mesmo padrao de `favorites`/`followers` (as duas
-- tabelas de relacionamento existentes no projeto), preservando o formato
-- de linha que o resto do app (Flutter/mappers) ja espera.

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  photo_url text,
  owner_id uuid not null references auth.users (id) on delete restrict,
  invite_code text not null unique,
  -- Ainda nao mantido por nenhum trigger/funcao - so a coluna existe nesta
  -- rodada (GROUP-01). Atualizar automaticamente a cada rolê/atividade do
  -- grupo e escopo do GROUP-02 (rolês) em diante; documentado aqui como
  -- divida tecnica explicita, nao esquecimento.
  last_activity_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint groups_name_not_blank check (length(trim(name)) > 0),
  constraint groups_invite_code_length check (length(invite_code) = 8)
);

-- `owner_id` usa `restrict` (mesmo padrao de restaurants/reviews - dado de
-- valor, nao descartavel como favorites/followers). Isso exige que
-- `delete_own_account()` reatribua `groups.owner_id` para o usuario
-- placeholder antes de apagar a conta - ver
-- 20260731091000_update_delete_own_account_for_groups.sql (migration
-- separada, corpo completo da funcao substituido, mesmo padrao ja usado em
-- 20260718212615/20260720130015/20260720130030 para correcoes retroativas).

create table public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),

  constraint group_members_unique unique (group_id, user_id)
);

-- Indices essenciais (GROUP-01 revisao). `unique(group_id, user_id)` acima
-- ja cobre buscas por group_id (coluna lider do indice da constraint) -
-- sem indice redundante para essa direcao. `invite_code` acima ja e unique
-- (indice automatico) - sem indice redundante. Os dois casos que
-- precisam de indice proprio, por nao serem cobertos por nenhuma
-- constraint: "todos os grupos de um usuario" e "grupos que um usuario
-- possui".
create index group_members_user_id_idx on public.group_members (user_id);
create index groups_owner_id_idx on public.groups (owner_id);

-- Reutiliza a funcao compartilhada de 20260718212615_add_set_updated_at_function.sql
-- - nao recriar essa logica aqui. `group_members` nao tem `updated_at`
-- (mesmo padrao de favorites/followers - sem semantica de update, so
-- insert/delete/role-update tratado via policy, nao via trigger).
create trigger set_groups_updated_at
  before update on public.groups
  for each row execute procedure public.set_updated_at();

-- Gerador do codigo de convite (RN definida nesta rodada, nao deixada
-- livre): 8 caracteres, charset sem caracteres ambiguos na leitura/
-- digitacao (sem I, O, 0, 1). `security definer` para que a checagem de
-- unicidade rode sem RLS mesmo quando chamada por dentro de create_group()/
-- regenerate_group_invite_code() (que ja rodam elevados) - sem isso, a
-- subquery contra `groups` seria filtrada pela policy de SELECT (so
-- membros veem grupos), tornando a checagem de unicidade pouco confiavel.
-- Sem GRANT EXECUTE a authenticated - uso interno apenas, nunca chamada
-- direto por RPC do cliente.
create function public.generate_group_invite_code()
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_charset text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_exists boolean;
begin
  loop
    v_code := '';
    for i in 1..8 loop
      v_code := v_code || substr(v_charset, (floor(random() * length(v_charset)) + 1)::int, 1);
    end loop;

    select exists (select 1 from public.groups where invite_code = v_code) into v_exists;
    exit when not v_exists;
  end loop;

  return v_code;
end;
$$;

-- Funcoes auxiliares para RLS (mesmo padrao de is_admin/has_admin_role,
-- ver user_roles.sql). `security definer` OBRIGATORIO aqui - sem isso,
-- reproduz exatamente o "Bug 3" ja catalogado no projeto
-- (20260720130030_fix_rbac_functions_security_definer.sql):
-- group_members_select_members (abaixo) chama is_group_member(), que
-- consulta group_members - sem security definer, essa consulta interna
-- reavalia a mesma policy, que chama a mesma funcao de novo (recursao
-- infinita, "stack depth limit exceeded").
--
-- admin herda os poderes de owner (RN desta rodada - "admin nao e owner,
-- mas owner tambem deve ter poderes de admin"): is_group_admin() retorna
-- true para role in ('owner', 'admin'); is_group_owner() e estrito.
create function public.is_group_member(uid uuid, gid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.group_members where user_id = uid and group_id = gid
  );
$$;

create function public.is_group_admin(uid uuid, gid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.group_members
    where user_id = uid and group_id = gid and role in ('owner', 'admin')
  );
$$;

create function public.is_group_owner(uid uuid, gid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.group_members
    where user_id = uid and group_id = gid and role = 'owner'
  );
$$;

alter table public.groups enable row level security;
alter table public.group_members enable row level security;

-- groups: fechado (diferente de restaurants/followers, que sao publicos
-- para qualquer autenticado) - so membros veem.
create policy "groups_select_members"
  on public.groups for select
  to authenticated
  using (public.is_group_member(auth.uid(), id));

-- INSERT bloqueado direto - so via create_group() (security definer),
-- que insere o grupo E o membro-owner na mesma transacao. Um INSERT
-- direto deixaria o grupo sem nenhum membro (orfao) ate uma segunda
-- chamada do cliente.
create policy "groups_insert_blocked"
  on public.groups for insert
  to authenticated
  with check (false);

create policy "groups_update_admin"
  on public.groups for update
  to authenticated
  using (public.is_group_admin(auth.uid(), id))
  with check (public.is_group_admin(auth.uid(), id));

create policy "groups_delete_owner"
  on public.groups for delete
  to authenticated
  using (public.is_group_owner(auth.uid(), id));

-- group_members: visivel so para membros do proprio grupo.
create policy "group_members_select_members"
  on public.group_members for select
  to authenticated
  using (public.is_group_member(auth.uid(), group_id));

-- INSERT bloqueado direto - so via join_group_by_invite_code()/
-- create_group() (security definer). O codigo de convite nao e uma
-- coluna desta tabela, entao nao ha como uma policy de INSERT validar
-- "o chamador conhece o codigo certo" sem uma funcao.
create policy "group_members_insert_blocked"
  on public.group_members for insert
  to authenticated
  with check (false);

-- UPDATE (promover/rebaixar): so owner, e nunca a propria linha do owner
-- (owner_id em `groups` e a fonte da verdade - trocar quem e owner exige
-- uma futura funcao de transferencia de propriedade, security definer,
-- atualizando groups.owner_id e group_members.role atomicamente; nao faz
-- parte do escopo do GROUP-01).
create policy "group_members_update_owner"
  on public.group_members for update
  to authenticated
  using (public.is_group_owner(auth.uid(), group_id) and role <> 'owner')
  with check (role <> 'owner');

-- DELETE: o proprio membro saindo (exceto se for o owner - RN desta
-- rodada, "o owner nao pode sair/ser removido do proprio grupo sem
-- transferir a propriedade antes") ou owner/admin removendo outro membro.
create policy "group_members_delete_self_or_admin"
  on public.group_members for delete
  to authenticated
  using (
    role <> 'owner'
    and (auth.uid() = user_id or public.is_group_admin(auth.uid(), group_id))
  );

-- create_group(): cria o grupo e insere o chamador como owner na mesma
-- transacao (evita o estado orfao mencionado acima). `security definer`
-- necessario porque INSERT direto em ambas as tabelas esta bloqueado por
-- policy para o cliente.
create function public.create_group(
  p_name text,
  p_description text default null,
  p_photo_url text default null
)
returns public.groups
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_group public.groups;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  insert into public.groups (name, description, photo_url, owner_id, invite_code)
  values (p_name, p_description, p_photo_url, v_user_id, public.generate_group_invite_code())
  returning * into v_group;

  insert into public.group_members (group_id, user_id, role)
  values (v_group.id, v_user_id, 'owner');

  return v_group;
end;
$$;

-- join_group_by_invite_code(): resolve o grupo pelo codigo e insere o
-- chamador como member. `on conflict do nothing` - reentrar num grupo que
-- ja e membro nao deve gerar erro (idempotente).
create function public.join_group_by_invite_code(p_invite_code text)
returns public.groups
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_group public.groups;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  select * into v_group from public.groups where invite_code = p_invite_code;
  if v_group.id is null then
    raise exception 'Código de convite inválido.';
  end if;

  insert into public.group_members (group_id, user_id, role)
  values (v_group.id, v_user_id, 'member')
  on conflict (group_id, user_id) do nothing;

  return v_group;
end;
$$;

-- regenerate_group_invite_code(): resposta ao risco levantado nesta
-- rodada (codigo permanente pode circular indefinidamente via captura de
-- tela) sem construir rotacao/expiracao automatica (fora do escopo do
-- MVP) - o owner troca o codigo sob demanda quando suspeitar de vazamento;
-- o codigo antigo para de funcionar imediatamente (unique constraint).
create function public.regenerate_group_invite_code(p_group_id uuid)
returns public.groups
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_group public.groups;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if not public.is_group_owner(v_user_id, p_group_id) then
    raise exception 'Apenas o proprietário do grupo pode gerar um novo código de convite.';
  end if;

  update public.groups
  set invite_code = public.generate_group_invite_code()
  where id = p_group_id
  returning * into v_group;

  return v_group;
end;
$$;

-- GRANT explicito (mesma disciplina de 20260720130000/20260725150000 -
-- Postgres concede privilegio de tabela e EXECUTE de funcao a
-- PUBLIC/authenticated de formas diferentes segundo o papel que cria o
-- objeto; sem isso, toda policy acima e inalcancavel). `anon` nao recebe
-- nada, mesma invariante do restante do projeto.
grant select, update, delete on public.groups to authenticated;
grant select, update, delete on public.group_members to authenticated;

revoke execute on function public.create_group(text, text, text) from public;
grant execute on function public.create_group(text, text, text) to authenticated;

revoke execute on function public.join_group_by_invite_code(text) from public;
grant execute on function public.join_group_by_invite_code(text) to authenticated;

revoke execute on function public.regenerate_group_invite_code(uuid) from public;
grant execute on function public.regenerate_group_invite_code(uuid) to authenticated;

-- is_group_member/is_group_admin/is_group_owner: sem REVOKE/GRANT
-- explicito - mesmo padrao de is_admin/has_admin_role/can_moderate
-- (user_roles.sql), que tambem sao funcoes de leitura booleana usadas
-- dentro de policies e nao tem grant proprio. Nao ha INSERT/UPDATE/
-- DELETE direto em `groups`/`group_members` nesta lista de GRANT
-- (bloqueados por policy, ver acima) - todo INSERT passa pelas 3 funcoes
-- acima.
