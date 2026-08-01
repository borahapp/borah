import '../../domain/event.dart';

/// Estado da listagem de rolês de um grupo (ROLÊ-03), sealed class -
/// mesmo shape de `GroupsListStatus`.
sealed class EventsListStatus {
  const EventsListStatus();
}

final class EventsListInitial extends EventsListStatus {
  const EventsListInitial();
}

final class EventsListLoading extends EventsListStatus {
  const EventsListLoading();
}

final class EventsListLoaded extends EventsListStatus {
  const EventsListLoaded(this.events);

  /// Ordenados por `scheduled_at` ascendente (mais próximo primeiro,
  /// `EventRepository.listByGroup`). Sem separação visual entre
  /// "Próximos"/"Realizados" nesta sprint - registrado como melhoria
  /// futura (relatório do ROLÊ-03).
  final List<Event> events;
}

final class EventsListEmpty extends EventsListStatus {
  const EventsListEmpty();
}

final class EventsListError extends EventsListStatus {
  const EventsListError(this.message);

  final String message;
}
