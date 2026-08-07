-- FASE C.1 - Owner deve conseguir sair do grupo (transferência de propriedade)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres - mesma ressalva
-- ja registrada em toda a familia GROUP-01/ROLE-01/BLOCO 5-8.
--
-- Lacuna deixada deliberadamente em aberto pela migration original
-- (20260731090000_create_groups_and_group_members.sql, comentario da
-- policy `group_members_update_owner`): "trocar quem e owner exige uma
-- futura funcao de transferencia de propriedade, security definer,
-- atualizando groups.owner_id e group_members.role atomicamente; nao faz
-- parte do escopo do GROUP-01." Esta migration fecha exatamente essa
-- lacuna, sem alterar nenhuma policy/trigger existente.
--
-- Por que uma funcao nova, e nao um UPDATE direto do cliente: a policy
-- `group_members_update_owner` ja bloqueia, de proposito, qualquer
-- tentativa de definir `role = 'owner'` via UPDATE direto (`with check
-- (role <> 'owner')`) - e nao ha nenhuma policy de UPDATE em `groups` que
-- permita ao cliente trocar `owner_id` (`groups_update_admin` cobre
-- nome/descricao/foto, nao esse campo). `security definer` e o mesmo
-- mecanismo ja usado por `regenerate_group_invite_code()` (mesmo arquivo
-- original, mesma tabela, tambem restrito ao owner) e por
-- `delete_own_account()` (20260731091000), que ja precisa manter a mesma
-- invariante ("owner_id sempre tem uma linha group_members com
-- role='owner'") ao reatribuir grupos por exclusao de conta - esta funcao
-- mantem a mesma invariante pelo mesmo motivo, so que por transferencia
-- deliberada em vez de exclusao de conta.
--
-- As 3 atualizacoes (groups.owner_id, papel do ex-owner, papel do novo
-- owner) rodam dentro da mesma funcao/transacao implicita - nunca existe
-- um instante com 2 owners ou 0 owners no grupo. O ex-owner vira 'admin'
-- (nao 'member') - menor mudanca de privilegio possivel, mesmo raciocinio
-- ja documentado no comentario original de is_group_admin() ("admin nao e
-- owner, mas owner tambem deve ter poderes de admin").

create function public.transfer_group_ownership(
  p_group_id uuid,
  p_new_owner_member_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_caller_id uuid := auth.uid();
  v_new_owner_user_id uuid;
begin
  if v_caller_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if not public.is_group_owner(v_caller_id, p_group_id) then
    raise exception 'Apenas o proprietário do grupo pode transferir a propriedade.';
  end if;

  select user_id into v_new_owner_user_id
  from public.group_members
  where id = p_new_owner_member_id and group_id = p_group_id;

  if v_new_owner_user_id is null then
    raise exception 'Membro não encontrado neste grupo.';
  end if;

  if v_new_owner_user_id = v_caller_id then
    raise exception 'Você já é o proprietário deste grupo.';
  end if;

  update public.groups
  set owner_id = v_new_owner_user_id
  where id = p_group_id;

  update public.group_members
  set role = 'admin'
  where group_id = p_group_id and user_id = v_caller_id;

  update public.group_members
  set role = 'owner'
  where id = p_new_owner_member_id;
end;
$$;

-- GRANT explicito - mesma disciplina ja usada para create_group()/
-- join_group_by_invite_code()/regenerate_group_invite_code() no arquivo
-- original: sem isto, a funcao e inalcancavel mesmo com security definer.
revoke execute on function public.transfer_group_ownership(uuid, uuid) from public;
grant execute on function public.transfer_group_ownership(uuid, uuid) to authenticated;
