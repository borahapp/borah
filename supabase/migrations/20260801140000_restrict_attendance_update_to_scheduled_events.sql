-- QA (BLOCO 9) - achado real: a policy "event_attendances_update_own"
-- (20260731092000_create_events_and_attendances.sql) só verificava
-- `auth.uid() = user_id`, sem checar o status do rolê. A UI já esconde
-- os botões de confirmar/recusar quando `event.status != 'scheduled'`
-- (`event_detail_page.dart`, `_AttendanceTile.isOwn`), mas isso é só
-- client-side - nada no banco impedia confirmar/recusar presença num
-- rolê já cancelado (ex.: corrida entre um admin cancelando e um
-- membro respondendo com a tela desatualizada, ou uma chamada direta à
-- API). Mesmo espírito de `can_review_event()` (BLOCO 4): a regra de
-- elegibilidade tem que existir no banco, não só na tela.
--
-- Consequência real de não corrigir: `notify_event_attendance_response_trigger`
-- (BLOCO 8) dispararia uma notificação de "respondeu ao rolê" para um
-- rolê já cancelado, confundindo o organizador.
drop policy "event_attendances_update_own" on public.event_attendances;

create policy "event_attendances_update_own"
  on public.event_attendances for update
  to authenticated
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.events e
      where e.id = event_id and e.status = 'scheduled'
    )
  )
  with check (auth.uid() = user_id);
