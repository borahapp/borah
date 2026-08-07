import 'package:meta/meta.dart';

import 'app_links_deep_link_service.dart';
import 'deep_link.dart';
import 'deep_link_service.dart';

/// Fachada estática de Deep Link do BORAH - mesmo padrão arquitetural
/// de `AppLogger`/`AppAnalytics`/`AppStorage`/`AppFeatureFlags`/
/// `AppFeedback`. Toda feature deve consumir Deep Link só através de
/// [DeepLinkDispatcher]/[DeepLinkReceiver] (nunca lendo [onLink]
/// diretamente) - esta fachada existe para que `DeepLinkDispatcher` (o
/// único consumidor real) nunca precise conhecer `package:app_links`.
abstract final class AppDeepLink {
  /// Sobrescreve o serviço em testes (`test/`), no lugar do serviço
  /// padrão (`app_links` real). Nunca deve ser usado em código de
  /// produção.
  @visibleForTesting
  static DeepLinkService? debugServiceOverride;

  static DeepLinkService? _defaultService;

  static DeepLinkService get _service {
    return debugServiceOverride ??
        (_defaultService ??= AppLinksDeepLinkService());
  }

  static Stream<DeepLink> get onLink => _service.onLink;
}
