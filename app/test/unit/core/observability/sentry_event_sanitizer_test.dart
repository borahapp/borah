import 'package:app/core/observability/sentry_event_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('sanitizeSentryEvent', () {
    test('redige JWT no valor da exceção', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dQw4w9WgXcQ';
      final event = SentryEvent(
        exceptions: [
          SentryException(type: 'AuthException', value: 'Token inválido: $jwt'),
        ],
      );

      final sanitized = sanitizeSentryEvent(event);

      expect(sanitized.exceptions!.single.value, isNot(contains(jwt)));
      expect(sanitized.exceptions!.single.value, contains('[REDACTED]'));
    });

    test('redige e-mail completo na mensagem do breadcrumb', () {
      final event = SentryEvent(
        breadcrumbs: [
          Breadcrumb(message: 'Falha ao reenviar para ana@borah.com'),
        ],
      );

      final sanitized = sanitizeSentryEvent(event);

      expect(sanitized.breadcrumbs!.single.message, isNot(contains('@')));
      expect(sanitized.breadcrumbs!.single.message, contains('[REDACTED]'));
    });

    test('redige valores de chaves sensíveis em tags', () {
      final event = SentryEvent(
        tags: {
          'auth_token': 'abc123',
          'refresh_token': 'def456',
          'screen': 'profile',
        },
      );

      final sanitized = sanitizeSentryEvent(event);

      expect(sanitized.tags!['auth_token'], '[REDACTED]');
      expect(sanitized.tags!['refresh_token'], '[REDACTED]');
      expect(sanitized.tags!['screen'], 'profile');
    });

    test('redige valores de chaves sensíveis em extra', () {
      final event = SentryEvent(
        // ignore: deprecated_member_use
        extra: {'password': 'senha123', 'retry_count': 3},
      );

      final sanitized = sanitizeSentryEvent(event);

      // ignore: deprecated_member_use
      expect(sanitized.extra!['password'], '[REDACTED]');
      // ignore: deprecated_member_use
      expect(sanitized.extra!['retry_count'], 3);
    });

    test('redige e-mail na mensagem do evento', () {
      final event = SentryEvent(
        message: const SentryMessage('Erro ao processar user@example.com'),
      );

      final sanitized = sanitizeSentryEvent(event);

      expect(sanitized.message!.formatted, isNot(contains('@')));
    });

    test('não altera texto sem dados sensíveis', () {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'FormatException',
            value: 'Não foi possível carregar a avaliação.',
          ),
        ],
      );

      final sanitized = sanitizeSentryEvent(event);

      expect(
        sanitized.exceptions!.single.value,
        'Não foi possível carregar a avaliação.',
      );
    });

    test('lida com evento sem exceptions/breadcrumbs/tags/extra', () {
      final event = SentryEvent();

      final sanitized = sanitizeSentryEvent(event);

      expect(sanitized.exceptions, isNull);
      expect(sanitized.breadcrumbs, isNull);
      expect(sanitized.tags, isNull);
      // ignore: deprecated_member_use
      expect(sanitized.extra, isNull);
    });
  });
}
