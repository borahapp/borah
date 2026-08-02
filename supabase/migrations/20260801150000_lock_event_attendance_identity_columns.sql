-- QA-15 (auditoria arquitetural) - achado real: a policy
-- "event_attendances_update_own" (20260731092000_create_events_and_
-- attendances.sql, endurecida em 20260801140000 para exigir
-- e.status='scheduled') só nunca restringiu QUAIS colunas um UPDATE
-- pode alterar - só quem pode fazer o UPDATE (o próprio `user_id`).
-- Nada no banco impedia o próprio usuário de, na mesma linha que ele já
-- tem permissão de UPDATE, também sobrescrever `event_id` para
-- apontar para QUALQUER outro evento agendado, inclusive de um grupo do
-- qual ele nunca foi membro:
--
--   update event_attendances
--   set event_id = '<evento-de-outro-grupo>', status = 'confirmed'
--   where id = '<minha-propria-linha>';
--
-- A `with check (auth.uid() = user_id)` da policy passa (a linha
-- continua sendo do próprio usuário) e a condição extra de
-- 20260801140000 (`e.status = 'scheduled'`) também passa, porque é
-- avaliada contra o evento ALVO (o novo `event_id`), não contra o
-- evento original. O resultado é uma presença "confirmed" fabricada
-- num evento de um grupo alheio, suficiente para satisfazer
-- `can_review_event()` (BLOCO 4, que só olha
-- status/scheduled_at/scheduled, nunca membership) e então inserir em
-- `event_reviews` (via `event_reviews_insert`) uma avaliação real,
-- visível aos membros verdadeiros do grupo alvo e capaz de distorcer
-- `events.average_rating`/`total_reviews` desse evento - quebra direta
-- do modelo de "grupo fechado" (GROUP-01).
--
-- Nenhum caminho legítimo do app precisa mudar `event_id`/`user_id`
-- depois de criada a linha: `EventRemoteDatasource.updateAttendanceStatus`
-- (única chamada de UPDATE em `event_attendances` em todo o app) só
-- envia `{'status': status}`. Travar essas duas colunas na própria
-- linha, via trigger (RLS não compara OLD/NEW da mesma coluna dentro de
-- uma única `with check`), fecha o buraco sem alterar nenhum
-- comportamento hoje exercitado pelo app - mesmo espírito de
-- `organizer_id` ser só histórico, nunca mutável por design.
create function public.prevent_event_attendance_reassignment()
returns trigger
language plpgsql
as $$
begin
  if new.event_id <> old.event_id or new.user_id <> old.user_id then
    raise exception 'event_attendances.event_id/user_id não podem ser alterados após a criação da linha.';
  end if;
  return new;
end;
$$;

create trigger prevent_event_attendance_reassignment_trigger
  before update on public.event_attendances
  for each row execute function public.prevent_event_attendance_reassignment();
