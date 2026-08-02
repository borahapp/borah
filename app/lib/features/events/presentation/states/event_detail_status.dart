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
  const EventDetailLoaded(this.details, this.canManage);

  final EventDetails details;

  /// Se o usuário atual é admin/owner do grupo deste rolê (BLOCO 3) -
  /// controla a exibição de cancelar/reagendar. Calculado uma vez no
  /// `load()` (`EventRepository.isGroupAdmin`), não muda durante a
  /// sessão da tela.
  final bool canManage;
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
  const EventDetailError(this.message, this.details, this.canManage);

  final String message;
  final EventDetails? details;

  /// Mesmo significado de `EventDetailLoaded.canManage` - `false` quando
  /// `details` também é `null` (falha do `load()` inicial, onde isso
  /// nunca chegou a ser calculado).
  final bool canManage;
}
