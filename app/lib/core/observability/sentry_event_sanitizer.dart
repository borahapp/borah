import 'package:sentry_flutter/sentry_flutter.dart';

const _redacted = '[REDACTED]';

/// Nomes de chave que nunca devem ser enviados ao Sentry, mesmo que
/// apareçam em breadcrumbs, tags ou dados extras.
final _sensitiveKeyPattern = RegExp(
  r'password|token|jwt|refresh|secret|authorization|api[_-]?key|access[_-]?key',
  caseSensitive: false,
);

/// Formato de um JWT (três segmentos base64url separados por `.`).
final _jwtPattern = RegExp(
  r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
);

/// E-mails completos - qualquer texto livre (mensagem de exceção,
/// breadcrumb) pode conter um por acidente.
final _emailPattern = RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+');

String _redactText(String input) {
  return input
      .replaceAll(_jwtPattern, _redacted)
      .replaceAll(_emailPattern, _redacted);
}

Map<String, dynamic>? _redactDynamicMap(Map<String, dynamic>? source) {
  if (source == null) return null;
  return source.map((key, value) {
    if (_sensitiveKeyPattern.hasMatch(key)) return MapEntry(key, _redacted);
    if (value is String) return MapEntry(key, _redactText(value));
    return MapEntry(key, value);
  });
}

Map<String, String>? _redactStringMap(Map<String, String>? source) {
  if (source == null) return null;
  return source.map((key, value) {
    if (_sensitiveKeyPattern.hasMatch(key)) return MapEntry(key, _redacted);
    return MapEntry(key, _redactText(value));
  });
}

/// Sanitiza um [SentryEvent] antes do envio (RC-03A — privacidade): nunca
/// envia senha, token, JWT, refresh token, e-mail completo ou qualquer
/// outro dado pessoal. Usado como `SentryOptions.beforeSend` — é o único
/// ponto de saída de dados para o Sentry, então toda sanitização do app
/// passa por aqui, sem exceção.
SentryEvent sanitizeSentryEvent(SentryEvent event) {
  final message = event.message;
  return event.copyWith(
    message: message == null
        ? null
        : SentryMessage(
            _redactText(message.formatted),
            template: message.template,
            params: message.params,
          ),
    exceptions: event.exceptions
        ?.map(
          (exception) => exception.copyWith(
            value: exception.value == null
                ? null
                : _redactText(exception.value!),
          ),
        )
        .toList(growable: false),
    breadcrumbs: event.breadcrumbs
        ?.map(
          (breadcrumb) => breadcrumb.copyWith(
            message: breadcrumb.message == null
                ? null
                : _redactText(breadcrumb.message!),
            data: _redactDynamicMap(breadcrumb.data),
          ),
        )
        .toList(growable: false),
    tags: _redactStringMap(event.tags),
    // ignore: deprecated_member_use
    extra: _redactDynamicMap(event.extra),
    // Nenhuma integração de HTTP (sentry_dio ou equivalente para o
    // supabase_flutter) está habilitada nesta rodada, então `event.request`
    // nunca é preenchido em primeiro lugar - nada a sanitizar aqui. Se uma
    // integração de HTTP for adicionada no futuro, esta função precisa
    // ganhar tratamento explícito para `request.headers`/`request.data`.
  );
}
