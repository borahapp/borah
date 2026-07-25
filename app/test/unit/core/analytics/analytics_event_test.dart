import 'package:app/core/analytics/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsEvent', () {
    test('toMap() inclui os campos padrão obrigatórios', () {
      final event = AnalyticsEvent(
        name: 'restaurant_viewed',
        environment: 'qa',
        appVersion: '1.0.0+1',
        timestamp: DateTime.utc(2026, 7, 25, 12),
      );

      expect(event.toMap(), {
        'event': 'restaurant_viewed',
        'timestamp': '2026-07-25T12:00:00.000Z',
        'environment': 'qa',
        'version': '1.0.0+1',
        'properties': <String, Object?>{},
      });
    });

    test('toMap() inclui screen e user_id quando informados', () {
      final event = AnalyticsEvent(
        name: 'profile_viewed',
        environment: 'production',
        appVersion: '1.0.0+1',
        screen: 'public_profile',
        userId: 'user-1',
        timestamp: DateTime.utc(2026, 7, 25),
      );

      final map = event.toMap();
      expect(map['screen'], 'public_profile');
      expect(map['user_id'], 'user-1');
    });

    test('screen e user_id ausentes quando nulos', () {
      final event = AnalyticsEvent(
        name: 'app_open',
        environment: 'development',
        appVersion: '1.0.0+1',
      );

      final map = event.toMap();
      expect(map.containsKey('screen'), isFalse);
      expect(map.containsKey('user_id'), isFalse);
    });

    test('timestamp default é o instante atual em UTC', () {
      final before = DateTime.now().toUtc();
      final event = AnalyticsEvent(
        name: 'app_open',
        environment: 'development',
        appVersion: '1.0.0+1',
      );
      final after = DateTime.now().toUtc();

      expect(
        event.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        event.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(event.timestamp.isUtc, isTrue);
    });

    test('properties é imutável', () {
      final event = AnalyticsEvent(
        name: 'search_performed',
        environment: 'qa',
        appVersion: '1.0.0+1',
        properties: {'query_length': 5},
      );

      expect(() => event.properties['extra'] = 'valor', throwsUnsupportedError);
    });

    test('properties aparece dentro de toMap()', () {
      final event = AnalyticsEvent(
        name: 'review_created',
        environment: 'qa',
        appVersion: '1.0.0+1',
        properties: {'review_id': 'rv-1', 'rating': 4.5},
      );

      expect(event.toMap()['properties'], {'review_id': 'rv-1', 'rating': 4.5});
    });
  });
}
