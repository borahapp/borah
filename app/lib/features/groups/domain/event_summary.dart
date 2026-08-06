/// Resumo mínimo de um Rolê, usado por [Group.nextEvent] (Sprint 3 do
/// RC-03, `RC03_DESIGN_GAP.md §1.3`) para a prévia de próximo rolê no
/// `GroupCard`. Deliberadamente não é o `Event` completo de
/// `features/events/domain/event.dart` (que carrega restaurante/status/
/// avaliação) - `groups/domain` não depende de `events/domain`, e a
/// prévia da Home não precisa desses campos. Cresce apenas quando uma
/// sprint futura precisar de mais dado aqui, sem quebrar esta API
/// (decisão explícita do usuário, RC-03 Sprint 3).
class EventSummary {
  const EventSummary({required this.id, required this.scheduledAt});

  final String id;
  final DateTime scheduledAt;
}
