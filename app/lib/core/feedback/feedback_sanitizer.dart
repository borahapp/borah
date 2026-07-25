import '../observability/pii_redaction.dart';

/// Sanitiza a mensagem de feedback antes do envio (RC-03E — privacidade):
/// nunca envia senha, JWT, refresh token, e-mail ou telefone, mesmo que
/// o usuário os cole por engano dentro do texto livre.
///
/// Reaproveita as primitivas já compartilhadas com Sentry (RC-03A) e
/// Analytics (RC-03C) em `pii_redaction.dart` — nenhuma chave a
/// verificar aqui (a mensagem de feedback é um texto livre único, não um
/// mapa de propriedades), então basta encadear as duas redações de
/// texto livre.
String sanitizeFeedbackMessage(String message) {
  return redactPhoneNumbers(redactSensitiveText(message));
}
