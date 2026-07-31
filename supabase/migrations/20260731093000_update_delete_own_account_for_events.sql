-- ROLE-01 - Correção retroativa de delete_own_account() para events
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente. Sera
-- validada contra Postgres 16 puro antes do commit - mesmo
-- procedimento do GROUP-01.
--
-- `events.organizer_id` (20260731092000) usa `on delete restrict` -
-- mesmo motivo/padrao de `groups.owner_id` (20260731091000): dado de
-- valor que nao deve desaparecer quando o organizador exclui a propria
-- conta (o grupo e os demais participantes continuam existindo). Sem
-- esta correcao, `delete_own_account()` falharia com violacao de FK
-- para qualquer usuario que ja tenha organizado um role - achado
-- detectado antes da implementacao, mesmo padrao do GROUP-01.
--
-- Apenas `CREATE OR REPLACE FUNCTION` - corpo idêntico à versão mais
-- recente (20260731091000_update_delete_own_account_for_groups.sql), só
-- adiciona a reatribuição de `events.organizer_id`. Mesmo padrão de
-- correção retroativa já usado em
-- 20260718212615/20260720130015/20260720130030/20260731091000 -
-- nenhuma policy/grant precisa ser alterada.
--
-- `event_attendances.user_id` usa `on delete cascade` (como
-- `group_members.user_id`) - a presença do usuário excluído desaparece
-- normalmente, sem necessidade de reatribuição (não é campo de autoria/
-- propriedade, é participação).

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

  with reassigned as (
    update public.groups set owner_id = v_placeholder_id
      where owner_id = v_user_id
      returning id
  )
  insert into public.group_members (group_id, user_id, role)
  select id, v_placeholder_id, 'owner' from reassigned
  on conflict (group_id, user_id) do update set role = 'owner';

  -- ROLE-01: reatribui roles organizados pelo usuario para o placeholder,
  -- pelo mesmo motivo/padrao acima. Diferente de groups.owner_id, nao
  -- ha uma linha de "presenca de organizador" que precise ser
  -- sincronizada em conjunto - a participacao do usuario em
  -- event_attendances (inclusive a sua propria, se houver) some via
  -- `on delete cascade` normalmente, e isso nao afeta o campo
  -- organizer_id de eventos que ele organizou (colunas independentes).
  update public.events set organizer_id = v_placeholder_id
    where organizer_id = v_user_id;

  delete from auth.users where id = v_user_id;
end;
$$;

-- Sem REVOKE/GRANT novo aqui - `create or replace function` preserva
-- os privilégios já concedidos ao objeto desde 20260725150000.
