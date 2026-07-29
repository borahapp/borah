import 'analytics_event.dart';

/// Interface de Analytics do BORAH (RC-03C). Nenhuma feature deve
/// depender diretamente do SDK de terceiros (PostHog) — toda comunicação
/// ocorre através de [AppAnalytics] (fachada estática), que por sua vez
/// só conhece esta interface. Trocar de provedor de Analytics no futuro
/// significa escrever uma nova implementação desta interface, sem tocar
/// em `lib/features/`.
abstract interface class AnalyticsService {
  /// Inicializa o SDK subjacente. Chamado uma única vez por
  /// `AppAnalytics.initialize()`, nunca diretamente por features.
  Future<void> setup();

  /// Envia (ou grava localmente, dependendo da implementação) um evento
  /// já sanitizado e com a convenção padrão de campos aplicada.
  Future<void> track(AnalyticsEvent event);

  /// Associa os eventos subsequentes a um usuário autenticado.
  Future<void> identify(String userId);

  /// Encerra a associação com o usuário atual (ex.: logout) — volta a
  /// tratar a sessão como anônima.
  Future<void> reset();
}
