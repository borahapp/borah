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
  // BETA-10B (sentry_flutter 9.x): `copyWith` foi depreciado em favor de
  // mutação direta dos campos - as classes do SDK deixaram de ser
  // imutáveis nesta major version (ver CHANGELOG "Mutable Data Classes").
  final message = event.message;
  if (message != null) {
    event.message = SentryMessage(
      redactSensitiveText(message.formatted),
      template: message.template,
      params: message.params,
    );
  }
  for (final exception in event.exceptions ?? const []) {
    final value = exception.value;
    if (value != null) exception.value = redactSensitiveText(value);
  }
  for (final breadcrumb in event.breadcrumbs ?? const []) {
    final breadcrumbMessage = breadcrumb.message;
    if (breadcrumbMessage != null) {
      breadcrumb.message = redactSensitiveText(breadcrumbMessage);
    }
    breadcrumb.data = redactDynamicMap(breadcrumb.data);
  }
  event.tags = redactStringMap(event.tags);
  // ignore: deprecated_member_use
  event.extra = redactDynamicMap(event.extra);
  // Nenhuma integração de HTTP (sentry_dio ou equivalente para o
  // supabase_flutter) está habilitada nesta rodada, então `event.request`
  // nunca é preenchido em primeiro lugar - nada a sanitizar aqui. Se uma
  // integração de HTTP for adicionada no futuro, esta função precisa
  // ganhar tratamento explícito para `request.headers`/`request.data`.
  return event;
}
