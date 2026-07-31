-- GROUP-01 - Correção retroativa de delete_own_account() para groups
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- `groups.owner_id` (20260731090000) usa `on delete restrict` - mesmo
-- padrao de restaurants.created_by/reviews.user_id, dado de valor que nao
-- deve desaparecer quando o proprietario exclui a propria conta (os
-- outros membros do grupo continuam existindo). Sem esta correcao,
-- `delete_own_account()` (20260725150000) falharia com violacao de FK
-- para qualquer usuario que seja owner de pelo menos um grupo,
-- silenciosamente impedindo a exclusao de conta - achado detectado antes
-- da implementacao (nao um bug reportado em produção).
--
-- Apenas `CREATE OR REPLACE FUNCTION` - corpo idêntico ao original
-- (20260725150000_create_delete_own_account_function.sql), só adiciona a
-- reatribuição de `groups.owner_id` para o usuário placeholder, na mesma
-- posição lógica das demais reatribuições (antes do DELETE final em
-- `auth.users`). Mesmo padrão de correção retroativa já usado em
-- 20260718212615/20260720130015/20260720130030 - nenhuma policy/grant
-- precisa ser alterada.

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_placeholder_id uuid := '00000000-0000-0000-0000-000000000001';
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if v_user_id = v_placeholder_id then
    raise exception 'Esta conta não pode ser excluída.';
  end if;

  update public.restaurants set created_by = v_placeholder_id
    where created_by = v_user_id;

  update public.reviews set user_id = v_placeholder_id
    where user_id = v_user_id;

  update public.comments set user_id = v_placeholder_id
    where user_id = v_user_id;

  update public.comment_reports set reported_by = v_placeholder_id
    where reported_by = v_user_id;

  update public.audit_logs set actor_id = v_placeholder_id
    where actor_id = v_user_id;

  -- GROUP-01: reatribui grupos que o usuario possui para o placeholder,
  -- pelo mesmo motivo/padrao das reatribuicoes acima (owner_id e
  -- `restrict`). A linha do usuario em `group_members` (role='owner')
  -- desaparece via `on delete cascade` no DELETE final abaixo - sem a
  -- segunda instrucao a seguir, o grupo ficaria com `owner_id` apontando
  -- para o placeholder mas nenhuma linha `group_members` correspondente
  -- (invariante "owner_id sempre tem uma linha group_members com
  -- role='owner'", definida no GROUP-01, ficaria quebrada). `on conflict
  -- ... do update` cobre o caso do placeholder já ser membro do grupo por
  -- uma exclusão de conta anterior.
  with reassigned as (
    update public.groups set owner_id = v_placeholder_id
      where owner_id = v_user_id
      returning id
  )
  insert into public.group_members (group_id, user_id, role)
  select id, v_placeholder_id, 'owner' from reassigned
  on conflict (group_id, user_id) do update set role = 'owner';

  delete from auth.users where id = v_user_id;
end;
$$;

-- Sem REVOKE/GRANT novo aqui - a função já tinha
-- `grant execute ... to authenticated` desde 20260725150000, e
-- `create or replace function` preserva os privilégios já concedidos ao
-- objeto (não precisa reconceder).
