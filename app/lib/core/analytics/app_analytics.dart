import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../environment/app_environment.dart';
import 'analytics_event.dart';
import 'analytics_property_sanitizer.dart';
import 'analytics_service.dart';
import 'posthog_analytics_service.dart';

/// Fachada estática de Analytics do BORAH (RC-03C) — mesmo padrão
/// arquitetural de `AppLogger`/`CrashReporting` (RC-03A/RC-03B). Toda
/// feature deve chamar só os métodos `trackXxx`/`identify`/`reset`
/// daqui; nenhuma feature deve conhecer [AnalyticsService] nem o SDK do
/// PostHog diretamente.
///
/// Convenção de nomenclatura dos eventos: `snake_case`, no formato
/// `substantivo_verbo_no_particípio` (ex.: `restaurant_favorited`,
/// `review_created`) — ver RC-03C_PRODUCT_ANALYTICS.md para a lista
/// completa e como adicionar novos eventos.
abstract final class AppAnalytics {
  /// Sobrescreve a implementação em testes (`test/`), no lugar de
  /// [PostHogAnalyticsService]. Nunca deve ser usado em código de
  /// produção.
  @visibleForTesting
  static AnalyticsService? debugServiceOverride;

  /// Sobrescreve se os eventos são enviados/repassados ao serviço em
  /// testes, no lugar da regra derivada de
  /// `AppEnvironment.environmentName`.
  @visibleForTesting
  static bool? debugSendsEventsOverride;

  static AnalyticsService get _service =>
      debugServiceOverride ?? _defaultService;

  static final AnalyticsService _defaultService = PostHogAnalyticsService();

  static String? _currentUserId;
  static String _appVersion = 'unknown';

  /// `false` só em Development — QA, Beta e Production enviam eventos
  /// (RC-03C). Development fica local para não poluir o projeto de
  /// Analytics real com dados de quem está desenvolvendo.
  static bool get isSendingEvents =>
      debugSendsEventsOverride ??
      AppEnvironment.environmentName != 'development';

  /// Inicializa a camada de Analytics — deve ser chamado uma única vez no
  /// bootstrap do app (`main.dart`), antes do primeiro evento. Lê a
  /// versão real do app instalado (`package_info_plus`, já usado como
  /// dependência transitiva por outros pacotes) e, se o ambiente atual
  /// envia eventos, inicializa o serviço subjacente.
  static Future<void> initialize() async {
    _appVersion = await _readAppVersion();
    if (isSendingEvents) {
      await _service.setup();
    }
  }

  static Future<String> _readAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Associa os eventos subsequentes ao usuário autenticado — chamar
  /// logo após login/cadastro/restauração de sessão bem-sucedidos, antes
  /// de rastrear o evento correspondente (para que o próprio evento de
  /// login/cadastro já carregue o `userId`).
  static Future<void> identify(String userId) {
    _currentUserId = userId;
    if (!isSendingEvents) return Future.value();
    return _service.identify(userId);
  }

  /// Encerra a associação com o usuário atual — chamar no logout, depois
  /// de rastrear o evento `logout` (para que esse evento ainda carregue
  /// o `userId` de quem estava saindo).
  static Future<void> reset() {
    _currentUserId = null;
    if (!isSendingEvents) return Future.value();
    return _service.reset();
  }

  /// Rastreia um evento genérico. Prefira os métodos `trackXxx` nomeados
  /// abaixo sempre que o evento já tiver um — `track()` cru fica para
  /// casos que ainda não têm um método dedicado.
  static Future<void> track(
    String eventName, {
    String? screen,
    Map<String, Object?> properties = const {},
  }) {
    if (!isSendingEvents) return Future.value();

    final event = AnalyticsEvent(
      name: eventName,
      environment: AppEnvironment.environmentName,
      appVersion: _appVersion,
      screen: screen,
      userId: _currentUserId,
      properties: sanitizeAnalyticsProperties(properties),
    );
    return _service.track(event);
  }

  // ---------------------------------------------------------------------
  // Eventos padronizados (RC-03C) — lista mínima exigida.
  // ---------------------------------------------------------------------

  static Future<void> trackAppOpen() => track('app_open');

  static Future<void> trackLoginSuccess() => track('login_success');

  static Future<void> trackLoginFailed({String? reason}) =>
      track('login_failed', properties: {'reason': ?reason});

  static Future<void> trackSignup() => track('signup');

  static Future<void> trackLogout() => track('logout');

  static Future<void> trackRestaurantViewed(
    String restaurantId, {
    String screen = 'restaurant_detail',
  }) => track(
    'restaurant_viewed',
    screen: screen,
    properties: {'restaurant_id': restaurantId},
  );

  static Future<void> trackRestaurantFavorited(String restaurantId) => track(
    'restaurant_favorited',
    properties: {'restaurant_id': restaurantId},
  );

  static Future<void> trackRestaurantUnfavorited(String restaurantId) => track(
    'restaurant_unfavorited',
    properties: {'restaurant_id': restaurantId},
  );

  static Future<void> trackReviewCreated(String reviewId, {double? rating}) =>
      track(
        'review_created',
        properties: {'review_id': reviewId, 'rating': ?rating},
      );

  static Future<void> trackReviewUpdated(String reviewId) =>
      track('review_updated', properties: {'review_id': reviewId});

  static Future<void> trackReviewDeleted(String reviewId) =>
      track('review_deleted', properties: {'review_id': reviewId});

  static Future<void> trackCommentCreated(String reviewId) =>
      track('comment_created', properties: {'review_id': reviewId});

  static Future<void> trackCommentDeleted(String commentId) =>
      track('comment_deleted', properties: {'comment_id': commentId});

  static Future<void> trackFeedOpened() => track('feed_opened', screen: 'feed');

  static Future<void> trackRankingOpened() =>
      track('ranking_opened', screen: 'rankings');

  static Future<void> trackProfileViewed(String profileUserId) => track(
    'profile_viewed',
    screen: 'public_profile',
    properties: {'profile_user_id': profileUserId},
  );

  static Future<void> trackProfileUpdated() =>
      track('profile_updated', screen: 'edit_profile');

  /// Não envia o texto da busca em si (dado potencialmente sensível
  /// digitado pelo usuário) — só o tamanho da string e a contagem de
  /// resultados, suficiente para métricas de uso sem risco de
  /// privacidade.
  static Future<void> trackSearchPerformed(String query, {int? resultCount}) =>
      track(
        'search_performed',
        screen: 'restaurants_search',
        properties: {
          'query_length': query.length,
          'result_count': ?resultCount,
        },
      );

  static Future<void> trackNotificationOpened(String notificationType) => track(
    'notification_opened',
    properties: {'notification_type': notificationType},
  );
}
