import 'package:app/core/analytics/analytics_property_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeAnalyticsProperties', () {
    test('redige JWT no valor de uma propriedade', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dQw4w9WgXcQ';

      final sanitized = sanitizeAnalyticsProperties({
        'debug_info': 'token atual: $jwt',
      });

      expect(sanitized['debug_info'], isNot(contains(jwt)));
      expect(sanitized['debug_info'], contains('[REDACTED]'));
    });

    test('redige e-mail completo no valor de uma propriedade', () {
      final sanitized = sanitizeAnalyticsProperties({
        'note': 'contato: ana@borah.com',
      });

      expect(sanitized['note'], isNot(contains('@')));
      expect(sanitized['note'], contains('[REDACTED]'));
    });

    test('redige telefone no valor de uma propriedade', () {
      final sanitized = sanitizeAnalyticsProperties({
        'note': 'ligar para +55 (11) 91234-5678',
      });

      expect(sanitized['note'], isNot(contains('91234-5678')));
      expect(sanitized['note'], contains('[REDACTED]'));
    });

    test('redige valores de chaves sensíveis independente do conteúdo', () {
      final sanitized = sanitizeAnalyticsProperties({
        'refresh_token': 'abc123',
        'password': 'hunter2',
        'restaurant_id': 'r-1',
      });

      expect(sanitized['refresh_token'], '[REDACTED]');
      expect(sanitized['password'], '[REDACTED]');
      expect(sanitized['restaurant_id'], 'r-1');
    });

    test('não altera valores não sensíveis (String, num, bool)', () {
      final sanitized = sanitizeAnalyticsProperties({
        'restaurant_id': 'r-1',
        'rating': 4.5,
        'result_count': 3,
        'is_favorite': true,
      });

      expect(sanitized, {
        'restaurant_id': 'r-1',
        'rating': 4.5,
        'result_count': 3,
        'is_favorite': true,
      });
    });

    test('mapa vazio permanece vazio', () {
      expect(sanitizeAnalyticsProperties(const {}), <String, Object?>{});
    });
  });
}
