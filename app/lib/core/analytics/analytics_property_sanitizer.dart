import '../observability/pii_redaction.dart';

/// Telefones — sequência de 8+ dígitos, com separadores opcionais
/// (`+`, `-`, espaço, parênteses). Específico do Analytics: o Sentry
/// (RC-03A) não precisa dessa regra porque eventos de erro raramente
/// carregam número de telefone em texto livre.
final _phonePattern = RegExp(r'(\+?\d[\d\s().-]{6,}\d)');

String _redactPhone(String input) =>
    input.replaceAll(_phonePattern, piiRedactedPlaceholder);

/// Sanitiza as propriedades de um evento de Analytics antes do envio
/// (RC-03C — privacidade): nunca envia senha, token, JWT, refresh token,
/// e-mail completo, telefone ou qualquer outro dado pessoal.
///
/// Reaproveita a redação de JWT/e-mail/chaves sensíveis já usada pelo
/// Sentry (RC-03A, `pii_redaction.dart`) e adiciona a redação de
/// telefone, exigida especificamente pela política de privacidade de
/// Analytics (RC-03C). É o único ponto de saída de dados para o
/// Analytics — toda sanitização passa por aqui, sem exceção.
Map<String, Object?> sanitizeAnalyticsProperties(
  Map<String, Object?> properties,
) {
  final redacted = redactDynamicMap(properties) ?? const {};
  return redacted.map((key, value) {
    if (value is String) return MapEntry(key, _redactPhone(value));
    return MapEntry(key, value);
  });
}
