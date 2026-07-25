import 'package:app/core/analytics/analytics_event.dart';
import 'package:app/core/analytics/posthog_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testa exclusivamente `flattenAnalyticsEventForPostHog` (função pura,
/// sem tocar o SDK). `Posthog()` lança `MissingPluginException` em
/// ambiente de teste sem um canal de plataforma registrado — diferente
/// do Sentry (RC-03A), cujo Hub padrão é um no-op puro em Dart — então
/// `PostHogAnalyticsService.setup/track/identify/reset` não são
/// exercitados diretamente aqui; a integração completa é validada via
/// `app_analytics_test.dart` (com `debugServiceOverride`).
void main() {
  group('flattenAnalyticsEventForPostHog', () {
    test('inclui environment/version/timestamp_utc sempre', () {
      final event = AnalyticsEvent(
        name: 'app_open',
        environment: 'qa',
        appVersion: '1.0.0+1',
        timestamp: DateTime.utc(2026, 7, 25, 12),
      );

      final flat = flattenAnalyticsEventForPostHog(event);

      expect(flat['environment'], 'qa');
      expect(flat['version'], '1.0.0+1');
      expect(flat['timestamp_utc'], '2026-07-25T12:00:00.000Z');
    });

    test('inclui screen e user_id quando informados', () {
      final event = AnalyticsEvent(
        name: 'profile_viewed',
        environment: 'production',
        appVersion: '1.0.0+1',
        screen: 'public_profile',
        userId: 'user-1',
      );

      final flat = flattenAnalyticsEventForPostHog(event);

      expect(flat['screen'], 'public_profile');
      expect(flat['user_id'], 'user-1');
    });

    test('omite screen e user_id quando nulos', () {
      final event = AnalyticsEvent(
        name: 'app_open',
        environment: 'development',
        appVersion: '1.0.0+1',
      );

      final flat = flattenAnalyticsEventForPostHog(event);

      expect(flat.containsKey('screen'), isFalse);
      expect(flat.containsKey('user_id'), isFalse);
    });

    test('achata properties para o mesmo nível (sem aninhamento)', () {
      final event = AnalyticsEvent(
        name: 'review_created',
        environment: 'qa',
        appVersion: '1.0.0+1',
        properties: {'review_id': 'rv-1', 'rating': 4.5},
      );

      final flat = flattenAnalyticsEventForPostHog(event);

      expect(flat['review_id'], 'rv-1');
      expect(flat['rating'], 4.5);
      expect(flat.containsKey('properties'), isFalse);
    });

    test(
      'omite propriedades com valor nulo (API do PostHog não aceita null)',
      () {
        final event = AnalyticsEvent(
          name: 'login_failed',
          environment: 'qa',
          appVersion: '1.0.0+1',
          properties: {'reason': null},
        );

        final flat = flattenAnalyticsEventForPostHog(event);

        expect(flat.containsKey('reason'), isFalse);
      },
    );
  });
}
