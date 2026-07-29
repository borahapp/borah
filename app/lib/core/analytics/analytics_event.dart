import 'package:meta/meta.dart';

/// Um evento de Analytics já com a convenção padrão de campos aplicada
/// (RC-03C) — nenhum evento deve ser montado fora de [AppAnalytics], que
/// é quem constrói instâncias desta classe.
///
/// Todo evento carrega: [name], [timestamp], [environment], [appVersion],
/// [screen] (quando aplicável), [userId] (quando disponível) e
/// [properties] (dados específicos do evento, já sanitizados por
/// `sanitizeAnalyticsProperties` antes de chegar aqui).
@immutable
class AnalyticsEvent {
  AnalyticsEvent({
    required this.name,
    required this.environment,
    required this.appVersion,
    this.screen,
    this.userId,
    Map<String, Object?> properties = const {},
    DateTime? timestamp,
  }) : properties = Map.unmodifiable(properties),
       timestamp = timestamp ?? DateTime.now().toUtc();

  /// Nome do evento, em snake_case (ex.: `restaurant_viewed`) — ver a
  /// convenção completa em RC-03C_PRODUCT_ANALYTICS.md.
  final String name;

  final DateTime timestamp;
  final String environment;
  final String appVersion;
  final String? screen;
  final String? userId;
  final Map<String, Object?> properties;

  /// Representação canônica do evento (RC-03C) — usada por testes e
  /// disponível para qualquer implementação de [AnalyticsService] que
  /// precise de uma forma serializável simples. Adaptações específicas de
  /// um provedor (ex.: achatar para o formato de `properties` esperado
  /// pelo PostHog) ficam na própria implementação, não aqui.
  Map<String, Object?> toMap() => {
    'event': name,
    'timestamp': timestamp.toIso8601String(),
    'environment': environment,
    'version': appVersion,
    if (screen != null) 'screen': screen,
    if (userId != null) 'user_id': userId,
    'properties': properties,
  };
}
