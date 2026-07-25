import 'package:app/core/analytics/analytics_event.dart';
import 'package:app/core/analytics/analytics_service.dart';
import 'package:app/core/analytics/app_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> trackedEvents = [];
  final List<String> identifiedUserIds = [];
  int resetCount = 0;
  int setupCount = 0;

  @override
  Future<void> setup() async {
    setupCount++;
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    trackedEvents.add(event);
  }

  @override
  Future<void> identify(String userId) async {
    identifiedUserIds.add(userId);
  }

  @override
  Future<void> reset() async {
    resetCount++;
  }
}

void main() {
  late _RecordingAnalyticsService service;

  setUp(() {
    service = _RecordingAnalyticsService();
    AppAnalytics.debugServiceOverride = service;
    AppAnalytics.debugSendsEventsOverride = true;
  });

  tearDown(() {
    AppAnalytics.debugServiceOverride = null;
    AppAnalytics.debugSendsEventsOverride = null;
  });

  group('comportamento por ambiente', () {
    test('isSendingEvents reflete o override em testes', () {
      AppAnalytics.debugSendsEventsOverride = false;
      expect(AppAnalytics.isSendingEvents, isFalse);

      AppAnalytics.debugSendsEventsOverride = true;
      expect(AppAnalytics.isSendingEvents, isTrue);
    });

    test(
      'com envio desabilitado (development), nenhum evento chega ao serviço',
      () async {
        AppAnalytics.debugSendsEventsOverride = false;

        await AppAnalytics.trackAppOpen();
        await AppAnalytics.trackLoginSuccess();
        await AppAnalytics.identify('user-1');
        await AppAnalytics.reset();

        expect(service.trackedEvents, isEmpty);
        expect(service.identifiedUserIds, isEmpty);
        expect(service.resetCount, 0);
      },
    );

    test(
      'com envio habilitado (qa/beta/production), eventos chegam ao serviço',
      () async {
        await AppAnalytics.trackAppOpen();

        expect(service.trackedEvents, hasLength(1));
      },
    );
  });

  group('identify/reset', () {
    test('identify() registra o userId no serviço', () async {
      await AppAnalytics.identify('user-1');

      expect(service.identifiedUserIds, ['user-1']);
    });

    test('userId identificado é anexado aos eventos subsequentes', () async {
      await AppAnalytics.identify('user-1');
      await AppAnalytics.trackFeedOpened();

      expect(service.trackedEvents.single.userId, 'user-1');
    });

    test(
      'reset() limpa o userId - eventos seguintes não o carregam mais',
      () async {
        await AppAnalytics.identify('user-1');
        await AppAnalytics.reset();
        await AppAnalytics.trackFeedOpened();

        expect(service.resetCount, 1);
        expect(service.trackedEvents.single.userId, isNull);
      },
    );
  });

  group('eventos padronizados (RC-03C)', () {
    test('trackAppOpen', () async {
      await AppAnalytics.trackAppOpen();
      expect(service.trackedEvents.single.name, 'app_open');
    });

    test('trackLoginSuccess', () async {
      await AppAnalytics.trackLoginSuccess();
      expect(service.trackedEvents.single.name, 'login_success');
    });

    test('trackLoginFailed com motivo', () async {
      await AppAnalytics.trackLoginFailed(reason: 'invalid_credentials');
      final event = service.trackedEvents.single;
      expect(event.name, 'login_failed');
      expect(event.properties['reason'], 'invalid_credentials');
    });

    test('trackLoginFailed sem motivo', () async {
      await AppAnalytics.trackLoginFailed();
      expect(
        service.trackedEvents.single.properties.containsKey('reason'),
        isFalse,
      );
    });

    test('trackSignup', () async {
      await AppAnalytics.trackSignup();
      expect(service.trackedEvents.single.name, 'signup');
    });

    test('trackLogout', () async {
      await AppAnalytics.trackLogout();
      expect(service.trackedEvents.single.name, 'logout');
    });

    test('trackRestaurantViewed', () async {
      await AppAnalytics.trackRestaurantViewed('r-1');
      final event = service.trackedEvents.single;
      expect(event.name, 'restaurant_viewed');
      expect(event.screen, 'restaurant_detail');
      expect(event.properties['restaurant_id'], 'r-1');
    });

    test('trackRestaurantFavorited', () async {
      await AppAnalytics.trackRestaurantFavorited('r-1');
      final event = service.trackedEvents.single;
      expect(event.name, 'restaurant_favorited');
      expect(event.properties['restaurant_id'], 'r-1');
    });

    test('trackRestaurantUnfavorited', () async {
      await AppAnalytics.trackRestaurantUnfavorited('r-1');
      final event = service.trackedEvents.single;
      expect(event.name, 'restaurant_unfavorited');
      expect(event.properties['restaurant_id'], 'r-1');
    });

    test('trackReviewCreated com rating', () async {
      await AppAnalytics.trackReviewCreated('rv-1', rating: 4.5);
      final event = service.trackedEvents.single;
      expect(event.name, 'review_created');
      expect(event.properties['review_id'], 'rv-1');
      expect(event.properties['rating'], 4.5);
    });

    test('trackReviewUpdated', () async {
      await AppAnalytics.trackReviewUpdated('rv-1');
      final event = service.trackedEvents.single;
      expect(event.name, 'review_updated');
      expect(event.properties['review_id'], 'rv-1');
    });

    test('trackReviewDeleted', () async {
      await AppAnalytics.trackReviewDeleted('rv-1');
      final event = service.trackedEvents.single;
      expect(event.name, 'review_deleted');
      expect(event.properties['review_id'], 'rv-1');
    });

    test('trackCommentCreated', () async {
      await AppAnalytics.trackCommentCreated('rv-1');
      final event = service.trackedEvents.single;
      expect(event.name, 'comment_created');
      expect(event.properties['review_id'], 'rv-1');
    });

    test('trackCommentDeleted', () async {
      await AppAnalytics.trackCommentDeleted('c-1');
      final event = service.trackedEvents.single;
      expect(event.name, 'comment_deleted');
      expect(event.properties['comment_id'], 'c-1');
    });

    test('trackFeedOpened', () async {
      await AppAnalytics.trackFeedOpened();
      final event = service.trackedEvents.single;
      expect(event.name, 'feed_opened');
      expect(event.screen, 'feed');
    });

    test('trackRankingOpened', () async {
      await AppAnalytics.trackRankingOpened();
      final event = service.trackedEvents.single;
      expect(event.name, 'ranking_opened');
      expect(event.screen, 'rankings');
    });

    test('trackProfileViewed', () async {
      await AppAnalytics.trackProfileViewed('user-2');
      final event = service.trackedEvents.single;
      expect(event.name, 'profile_viewed');
      expect(event.properties['profile_user_id'], 'user-2');
    });

    test('trackProfileUpdated', () async {
      await AppAnalytics.trackProfileUpdated();
      expect(service.trackedEvents.single.name, 'profile_updated');
    });

    test(
      'trackSearchPerformed nunca envia o texto da busca, só o tamanho',
      () async {
        await AppAnalytics.trackSearchPerformed(
          'pizzaria italiana',
          resultCount: 5,
        );
        final event = service.trackedEvents.single;
        expect(event.name, 'search_performed');
        expect(event.properties['query_length'], 'pizzaria italiana'.length);
        expect(event.properties['result_count'], 5);
        expect(event.properties.values, isNot(contains('pizzaria italiana')));
      },
    );

    test('trackNotificationOpened', () async {
      await AppAnalytics.trackNotificationOpened('new_follower');
      final event = service.trackedEvents.single;
      expect(event.name, 'notification_opened');
      expect(event.properties['notification_type'], 'new_follower');
    });
  });

  group('sanitização (RC-03A/RC-03C)', () {
    test(
      'propriedades sensíveis são redigidas antes de chegar ao serviço',
      () async {
        await AppAnalytics.track(
          'debug_event',
          properties: {'password': 'hunter2', 'restaurant_id': 'r-1'},
        );

        final event = service.trackedEvents.single;
        expect(event.properties['password'], '[REDACTED]');
        expect(event.properties['restaurant_id'], 'r-1');
      },
    );
  });

  group('campos padrão', () {
    test('todo evento carrega environment e appVersion', () async {
      await AppAnalytics.trackAppOpen();

      final event = service.trackedEvents.single;
      expect(event.environment, isNotEmpty);
      expect(event.appVersion, isNotEmpty);
      expect(event.timestamp, isNotNull);
    });
  });
}
