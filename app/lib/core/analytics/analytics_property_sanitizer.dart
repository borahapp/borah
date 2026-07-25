import '../observability/pii_redaction.dart';

/// Sanitiza as propriedades de um evento de Analytics antes do envio
/// (RC-03C — privacidade): nunca envia senha, token, JWT, refresh token,
/// e-mail completo, telefone ou qualquer outro dado pessoal.
///
/// Reaproveita a redação de JWT/e-mail/chaves sensíveis e de telefone
/// já compartilhadas em `pii_redaction.dart` (RC-03A/RC-03E). É o único
/// ponto de saída de dados para o Analytics — toda sanitização passa
/// por aqui, sem exceção.
Map<String, Object?> sanitizeAnalyticsProperties(
  Map<String, Object?> properties,
) {
  final redacted = redactDynamicMap(properties) ?? const {};
  return redacted.map((key, value) {
    if (value is String) return MapEntry(key, redactPhoneNumbers(value));
    return MapEntry(key, value);
  });
}
