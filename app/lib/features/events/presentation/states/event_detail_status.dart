import '../../domain/event_details.dart';

/// Estado do Detalhe do Rolê (ROLÊ-03), sealed class - mesmo padrão de
/// `GroupDetailStatus`.
sealed class EventDetailStatus {
  const EventDetailStatus();
}

final class EventDetailInitial extends EventDetailStatus {
  const EventDetailInitial();
}

final class EventDetailLoading extends EventDetailStatus {
  const EventDetailLoading();
}

final class EventDetailLoaded extends EventDetailStatus {
  const EventDetailLoaded(this.details);

  final EventDetails details;
}

/// Confirmar/recusar presença é uma atualização otimista (mesmo padrão
/// de `FavoriteToggleController`/`FavoriteToggleError`): o toque muda
/// [details] imediatamente, antes da resposta do servidor. Se a chamada
/// falhar, `EventDetailController` reverte [details] para o valor
/// anterior à tentativa e emite este estado - a UI sempre mostra o
/// status real das presenças (nunca um estado otimista "preso" na
/// tela), com [message] exibido como feedback pontual (snackbar), não
/// como tela cheia de erro.
///
/// [details] é `null` apenas quando o próprio `load()` inicial falha
/// (nenhum rolê jamais foi carregado) - nesse caso a tela mostra o
/// estado de erro de página inteira, mesmo padrão de `GroupDetailError`.
final class EventDetailError extends EventDetailStatus {
  const EventDetailError(this.message, this.details);

  final String message;
  final EventDetails? details;
}
