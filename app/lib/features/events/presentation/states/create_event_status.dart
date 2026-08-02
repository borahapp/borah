import '../../domain/event.dart';

/// Estado da criação de rolê (ROLÊ-02) - mesmo padrão de
/// `CreateGroupStatus`: sealed class, um estado por fase da operação
/// única desta tela (não há "load", só "save").
sealed class CreateEventStatus {
  const CreateEventStatus();
}

final class CreateEventInitial extends CreateEventStatus {
  const CreateEventInitial();
}

final class CreateEventSaving extends CreateEventStatus {
  const CreateEventSaving();
}

final class CreateEventSaveSuccess extends CreateEventStatus {
  const CreateEventSaveSuccess(this.event);

  final Event event;
}

final class CreateEventError extends CreateEventStatus {
  const CreateEventError(this.message);

  final String message;
}
