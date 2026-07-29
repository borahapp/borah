/// Primitivas de redação de dados sensíveis (RC-03A), compartilhadas
/// entre o sanitizador de eventos do Sentry (`sentry_event_sanitizer.dart`)
/// e o sanitizador de propriedades de Analytics (RC-03C,
/// `core/analytics/analytics_property_sanitizer.dart`). Nenhum dos dois
/// deve duplicar estes padrões — qualquer ajuste feito aqui vale para os
/// dois canais de saída de dados do app.
library;

const piiRedactedPlaceholder = '[REDACTED]';

/// Nomes de chave que nunca devem ser enviados, mesmo que apareçam em
/// breadcrumbs, tags, propriedades ou dados extras.
final sensitiveKeyPattern = RegExp(
  r'password|token|jwt|refresh|secret|authorization|api[_-]?key|access[_-]?key',
  caseSensitive: false,
);

/// Formato de um JWT (três segmentos base64url separados por `.`).
final jwtPattern = RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+');

/// E-mails completos — qualquer texto livre (mensagem de exceção,
/// breadcrumb, propriedade de evento) pode conter um por acidente.
final emailPattern = RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+');

/// Redige JWT e e-mail de um texto livre. Não inclui telefone — isso é
/// opt-in via [redactPhoneNumbers] (nem todo consumidor desta primitiva
/// precisa da mesma política de privacidade — o Sentry, RC-03A, não
/// aplica essa regra).
String redactSensitiveText(String input) {
  return input
      .replaceAll(jwtPattern, piiRedactedPlaceholder)
      .replaceAll(emailPattern, piiRedactedPlaceholder);
}

/// Telefones — sequência de 8+ dígitos, com separadores opcionais
/// (`+`, `-`, espaço, parênteses). Extraída aqui (RC-03E) para ser
/// reaproveitada tanto pelo Analytics (RC-03C) quanto pelo Feedback
/// (RC-03E) sem duplicar o regex — continua opt-in, nunca aplicada pelo
/// sanitizador do Sentry.
final phonePattern = RegExp(r'(\+?\d[\d\s().-]{6,}\d)');

String redactPhoneNumbers(String input) {
  return input.replaceAll(phonePattern, piiRedactedPlaceholder);
}

Map<String, dynamic>? redactDynamicMap(Map<String, dynamic>? source) {
  if (source == null) return null;
  return source.map((key, value) {
    if (sensitiveKeyPattern.hasMatch(key)) {
      return MapEntry(key, piiRedactedPlaceholder);
    }
    if (value is String) return MapEntry(key, redactSensitiveText(value));
    return MapEntry(key, value);
  });
}

Map<String, String>? redactStringMap(Map<String, String>? source) {
  if (source == null) return null;
  return source.map((key, value) {
    if (sensitiveKeyPattern.hasMatch(key)) {
      return MapEntry(key, piiRedactedPlaceholder);
    }
    return MapEntry(key, redactSensitiveText(value));
  });
}
