-- RC-04C - LGPD & Account Deletion
--
-- Função de auto-exclusão de conta (RN-003/ET-04; PB-04 §7/§10). Não
-- existe nenhum método client-side no Supabase para um usuário excluir
-- a própria linha de `auth.users`: `GoTrueClient` (SDK usado pelo app,
-- `gotrue-2.26.0`) não expõe nenhum "deleteAccount"/"deleteUser" -
-- `deleteUser()` só existe em `GoTrueAdminApi` (`auth.admin`), que exige
-- a `SERVICE_ROLE_KEY` - nunca presente no app mobile (RC-04A). O
-- padrão recomendado pela própria comunidade Supabase para autoexclusão
-- sem Edge Function (este projeto não tem essa infraestrutura - mesma
-- decisão já registrada no DV-08) é uma função `SECURITY DEFINER`
-- travada em `auth.uid()`, exposta via RPC.
--
-- Sequência (nesta ordem, por causa das constraints `on delete
-- restrict` em reviews/comments/comment_reports/audit_logs e da
-- ausência de cascata em restaurants.created_by - ver a análise
-- completa em 20260725140000_create_deleted_user_placeholder.sql):
-- 1. Reatribui restaurants/reviews/comments/comment_reports/audit_logs
--    do usuário para a conta placeholder "Usuário removido".
-- 2. Apaga a linha de `auth.users` do próprio chamador - todo o
--    restante (profiles, favorites, followers, review_likes,
--    notifications, notification_preferences, user_progress,
--    user_badges, user_roles, feedback) é removido automaticamente por
--    `on delete cascade`, sem nenhuma ação adicional desta função.
--
-- Segurança: `auth.uid()` é resolvido pelo próprio Postgres a partir do
-- JWT da sessão - não é um parâmetro da função, então não pode ser
-- manipulado pelo chamador para apagar a conta de outra pessoa (RC-04C
-- §Segurança - "nenhum usuário consegue excluir outra conta"). Nenhuma
-- operação administrativa é afetada: `is_admin`/`has_admin_role`/
-- `can_moderate` continuam consultando `user_roles` normalmente; a
-- única mudança é que, se o usuário excluído tinha um papel
-- administrativo, esse papel desaparece junto (cascata de
-- `user_roles.user_id`), como esperado. `search_path` travado (mesmo
-- padrão de todas as funções `SECURITY DEFINER` do projeto, ver
-- RC-04A §3.1).
--
-- ATENCAO: como toda migration deste projeto, escrita e revisada
-- estaticamente, sem validação contra uma instância real do
-- Supabase/Postgres (ver AR-06/EX-01B).

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

  delete from auth.users where id = v_user_id;
end;
$$;

-- Postgres concede EXECUTE a PUBLIC por padrão em toda função nova -
-- revogado explicitamente antes de conceder só a `authenticated`,
-- mesma disciplina de GRANT explícito já aplicada a toda tabela do
-- projeto (lição da correção de GRANT da FASE 5/6, RC-04A).
revoke execute on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
