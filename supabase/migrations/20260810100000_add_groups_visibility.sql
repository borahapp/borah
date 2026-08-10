-- FASE SOCIAL 3 - groups.visibility
--
-- 'private' (default) preserva todo grupo já existente sem mudança -
-- requisito explícito do produto ("grupos existentes devem continuar
-- private, só novos grupos podem ser public por escolha do criador").
-- Nullable não faz sentido aqui (diferente de profiles.username):
-- todo grupo precisa de um valor definido desde a criação.

alter table public.groups
  add column visibility text not null default 'private'
    check (visibility in ('private', 'public'));

-- groups_select_members (GROUP-01) só permitia SELECT a membros. Agora
-- também permite qualquer autenticado ver um grupo public, mesmo sem
-- ser membro - é exatamente essa leitura que alimenta busca/destaque/
-- perfil público de grupo. group_members_select_members (lista de
-- membros) e group_activity_feed() (RPC) NÃO são tocados aqui - decisão
-- de produto explícita: não-membro só vê dados básicos do grupo
-- (nome/foto/descrição/contagem), nunca a lista de membros nem a
-- atividade.
drop policy "groups_select_members" on public.groups;
create policy "groups_select_members"
  on public.groups for select
  to authenticated
  using (public.is_group_member(auth.uid(), id) or visibility = 'public');

-- create_group() ganha p_visibility (default 'private' - chamar sem o
-- parâmetro preserva o comportamento de sempre). Corpo idêntico ao
-- original (20260731090000) além da coluna nova.
create or replace function public.create_group(
  p_name text,
  p_description text default null,
  p_photo_url text default null,
  p_visibility text default 'private'
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

  insert into public.groups (name, description, photo_url, owner_id, invite_code, visibility)
  values (p_name, p_description, p_photo_url, v_user_id, public.generate_group_invite_code(), p_visibility)
  returning * into v_group;

  insert into public.group_members (group_id, user_id, role)
  values (v_group.id, v_user_id, 'owner');

  return v_group;
end;
$$;

-- join_public_group(): entrada instantânea num grupo public, sem
-- código de convite - único caminho novo de INSERT em group_members
-- além de create_group()/join_group_by_invite_code() já existentes.
-- group_members_insert_blocked (GROUP-01) continua bloqueando INSERT
-- direto do cliente; esta função contorna isso do mesmo jeito que as
-- outras duas (SECURITY DEFINER), validando visibility internamente -
-- nunca confia que o cliente já checou isso na UI. Idempotente (`on
-- conflict do nothing`), mesmo padrão de join_group_by_invite_code().
create function public.join_public_group(p_group_id uuid)
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

  select * into v_group from public.groups where id = p_group_id;
  if v_group.id is null then
    raise exception 'Grupo não encontrado.';
  end if;
  if v_group.visibility <> 'public' then
    raise exception 'Este grupo não é público.';
  end if;

  insert into public.group_members (group_id, user_id, role)
  values (p_group_id, v_user_id, 'member')
  on conflict (group_id, user_id) do nothing;

  return v_group;
end;
$$;

-- create_group() muda de assinatura (4º parâmetro) - CREATE OR REPLACE
-- com a lista de parâmetros nova substitui a função de 3 parâmetros;
-- GRANT precisa ser refeito para a assinatura nova (Postgres trata
-- funções com listas de parâmetros diferentes como objetos distintos).
revoke execute on function public.create_group(text, text, text, text) from public;
grant execute on function public.create_group(text, text, text, text) to authenticated;

revoke execute on function public.join_public_group(uuid) from public;
grant execute on function public.join_public_group(uuid) to authenticated;
