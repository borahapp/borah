import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../logger/app_logger.dart';

/// RC-04E: traduz mensagens técnicas do Supabase (majoritariamente em
/// inglês) para um texto amigável em português. Aplicado apenas nos
/// fluxos de maior visibilidade do Beta - login, cadastro, recuperação/
/// redefinição de senha e exclusão de conta (ver
/// `RC-04E_CLOSED_BETA.md`). Os demais repositórios (perfil,
/// restaurantes, avaliações, gamificação, favoritos, notificações etc.)
/// continuam repassando `e.message` diretamente - registrado como
/// backlog priorizado, não expandido nesta rodada.
///
/// Mapeamento centralizado num único lugar (evita traduções espalhadas
/// pelo código) com fallback seguro: mensagem desconhecida nunca é
/// escondida do usuário, apenas repassada como veio do Supabase. O texto
/// técnico original sempre é preservado via `AppLogger.warning` (chega
/// ao Sentry como WARNING+) para observabilidade, mesmo quando a
/// mensagem exibida ao usuário já foi traduzida.
abstract final class SupabaseErrorTranslator {
  static String translateAuthError(AuthException error) {
    AppLogger.warning(
      'Erro de autenticação traduzido para o usuário.',
      tag: 'errors/SupabaseErrorTranslator',
      error: error,
    );
    return _translate(error.code, error.message) ?? error.message;
  }

  static String translatePostgrestError(PostgrestException error) {
    AppLogger.warning(
      'Erro do PostgREST traduzido para o usuário.',
      tag: 'errors/SupabaseErrorTranslator',
      error: error,
    );
    return _translate(error.code, error.message) ?? error.message;
  }

  /// Casa primeiro pelo `code` estruturado (mais confiável, quando
  /// presente) e, como reforço, por trechos conhecidos da mensagem em
  /// inglês (nem toda resposta do Supabase populou `code` nas versões
  /// mais antigas do servidor). Fonte dos códigos:
  /// https://supabase.com/docs/guides/auth/debugging/error-codes.
  static String? _translate(String? code, String message) {
    final normalized = message.toLowerCase();

    // Falha de transporte (sem internet, DNS, servidor inalcançável) -
    // chega aqui como `AuthException` com a mensagem crua da exceção de
    // rede subjacente (`ClientException`/`SocketException` etc.), sem
    // `code` estruturado (nunca chegou a uma resposta HTTP do Supabase
    // para ter um). Verificada antes dos demais casos, puramente por
    // texto - achado real (BORAH, verificação manual contra um backend
    // indisponível): sem isto, o usuário via a mensagem técnica crua
    // (ex. "ClientException: Failed to fetch, uri=...").
    if (normalized.contains('clientexception') ||
        normalized.contains('failed to fetch') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection failed') ||
        normalized.contains('network is unreachable')) {
      return 'Não foi possível conectar. Verifique sua conexão com a '
          'internet e tente novamente.';
    }

    if (code == 'invalid_credentials' ||
        normalized.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        normalized.contains('already registered') ||
        normalized.contains('already exists')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (code == 'email_not_confirmed' ||
        normalized.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de continuar.';
    }
    if (code == 'otp_expired' ||
        code == 'flow_state_expired' ||
        normalized.contains('expired')) {
      return 'Este link expirou. Solicite um novo.';
    }
    if (code == 'weak_password' ||
        normalized.contains('password should be at least') ||
        normalized.contains('weak')) {
      return 'A senha não atende aos requisitos mínimos de segurança.';
    }
    if (code == 'same_password' ||
        normalized.contains('different from the old password')) {
      return 'A nova senha deve ser diferente da senha atual.';
    }
    if (code == 'over_email_send_rate_limit' ||
        code == 'over_request_rate_limit' ||
        code == 'over_sms_send_rate_limit' ||
        normalized.contains('rate limit')) {
      return 'Muitas tentativas em pouco tempo. Aguarde alguns minutos e '
          'tente novamente.';
    }

    return null;
  }
}
