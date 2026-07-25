import 'package:sentry_flutter/sentry_flutter.dart';

import 'pii_redaction.dart';

/// Sanitiza um [SentryEvent] antes do envio (RC-03A — privacidade): nunca
/// envia senha, token, JWT, refresh token, e-mail completo ou qualquer
/// outro dado pessoal. Usado como `SentryOptions.beforeSend` — é o único
/// ponto de saída de dados para o Sentry, então toda sanitização do app
/// passa por aqui, sem exceção. As primitivas de redação em si vivem em
/// `pii_redaction.dart` (RC-03C), compartilhadas com o sanitizador de
/// Analytics.
SentryEvent sanitizeSentryEvent(SentryEvent event) {
  final message = event.message;
  return event.copyWith(
    message: message == null
        ? null
        : SentryMessage(
            redactSensitiveText(message.formatted),
            template: message.template,
            params: message.params,
          ),
    exceptions: event.exceptions
        ?.map(
          (exception) => exception.copyWith(
            value: exception.value == null
                ? null
                : redactSensitiveText(exception.value!),
          ),
        )
        .toList(growable: false),
    breadcrumbs: event.breadcrumbs
        ?.map(
          (breadcrumb) => breadcrumb.copyWith(
            message: breadcrumb.message == null
                ? null
                : redactSensitiveText(breadcrumb.message!),
            data: redactDynamicMap(breadcrumb.data),
          ),
        )
        .toList(growable: false),
    tags: redactStringMap(event.tags),
    // ignore: deprecated_member_use
    extra: redactDynamicMap(event.extra),
    // Nenhuma integração de HTTP (sentry_dio ou equivalente para o
    // supabase_flutter) está habilitada nesta rodada, então `event.request`
    // nunca é preenchido em primeiro lugar - nada a sanitizar aqui. Se uma
    // integração de HTTP for adicionada no futuro, esta função precisa
    // ganhar tratamento explícito para `request.headers`/`request.data`.
  );
}
