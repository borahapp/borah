import 'package:app/core/feedback/feedback_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeFeedbackMessage', () {
    test('redige JWT na mensagem', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dQw4w9WgXcQ';

      final sanitized = sanitizeFeedbackMessage('meu token é $jwt, ajuda!');

      expect(sanitized, isNot(contains(jwt)));
      expect(sanitized, contains('[REDACTED]'));
    });

    test('redige e-mail completo na mensagem', () {
      final sanitized = sanitizeFeedbackMessage(
        'pode me responder em ana@borah.com?',
      );

      expect(sanitized, isNot(contains('@')));
      expect(sanitized, contains('[REDACTED]'));
    });

    test('redige telefone na mensagem', () {
      final sanitized = sanitizeFeedbackMessage(
        'me liga no +55 (11) 91234-5678',
      );

      expect(sanitized, isNot(contains('91234-5678')));
      expect(sanitized, contains('[REDACTED]'));
    });

    test('não altera mensagem sem dados sensíveis', () {
      const message = 'Adorei o app, só achei o botão de favoritar escondido.';

      expect(sanitizeFeedbackMessage(message), message);
    });
  });
}
