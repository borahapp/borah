import 'package:app/core/errors/supabase_error_translator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('translateAuthError', () {
    test('invalid_credentials (por código) -> mensagem em português', () {
      final message = SupabaseErrorTranslator.translateAuthError(
        const AuthApiException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      );

      expect(message, 'E-mail ou senha incorretos.');
    });

    test('mensagem legada "Invalid login credentials" sem código -> mesma '
        'tradução (fallback por texto)', () {
      final message = SupabaseErrorTranslator.translateAuthError(
        const AuthException('Invalid login credentials'),
      );

      expect(message, 'E-mail ou senha incorretos.');
    });

    test('user_already_exists -> "Este e-mail já está cadastrado."', () {
      final message = SupabaseErrorTranslator.translateAuthError(
        const AuthApiException(
          'User with this email already exists',
          code: 'user_already_exists',
        ),
      );

      expect(message, 'Este e-mail já está cadastrado.');
    });

    test('email_not_confirmed -> mensagem de confirmação pendente', () {
      final message = SupabaseErrorTranslator.translateAuthError(
        const AuthApiException(
          'Email not confirmed',
          code: 'email_not_confirmed',
        ),
      );

      expect(message, 'Confirme seu e-mail antes de continuar.');
    });

    test('otp_expired (link de recuperação) -> mensagem de link expirado', () {
      final message = SupabaseErrorTranslator.translateAuthError(
        const AuthApiException(
          'OTP code for this sign-in has expired',
          code: 'otp_expired',
        ),
      );

      expect(message, 'Este link expirou. Solicite um novo.');
    });

    test('same_password -> mensagem de senha repetida', () {
      final message = SupabaseErrorTranslator.translateAuthError(
        const AuthApiException(
          'New password should be different from the old password',
          code: 'same_password',
        ),
      );

      expect(message, 'A nova senha deve ser diferente da senha atual.');
    });

    test('over_email_send_rate_limit -> mensagem de limite de tentativas', () {
      final message = SupabaseErrorTranslator.translateAuthError(
        const AuthApiException(
          'Email rate limit exceeded',
          code: 'over_email_send_rate_limit',
        ),
      );

      expect(
        message,
        'Muitas tentativas em pouco tempo. Aguarde alguns minutos e tente '
        'novamente.',
      );
    });

    test('código/mensagem desconhecidos -> repassa a mensagem original '
        '(fallback seguro, nunca esconde o erro)', () {
      final message = SupabaseErrorTranslator.translateAuthError(
        const AuthApiException(
          'Something unexpected happened on the server',
          code: 'unmapped_error_code',
        ),
      );

      expect(message, 'Something unexpected happened on the server');
    });
  });

  group('translatePostgrestError', () {
    test('mensagem desconhecida -> repassa a mensagem original', () {
      final message = SupabaseErrorTranslator.translatePostgrestError(
        const PostgrestException(message: 'permission denied for table x'),
      );

      expect(message, 'permission denied for table x');
    });
  });
}
