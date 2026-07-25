/// Níveis de log do BORAH (RC-03B), em ordem crescente de severidade —
/// a ordem do enum importa: comparações usam `.index`.
enum AppLogLevel {
  trace(300),
  debug(500),
  info(800),
  warning(900),
  error(1000),
  fatal(1200);

  const AppLogLevel(this.developerLogLevel);

  /// Valor de severidade usado por `dart:developer.log` (parâmetro
  /// `level:`) — não tem relação com o Sentry, que é mapeado
  /// separadamente em `core/observability/crash_reporting.dart`.
  final int developerLogLevel;

  String get label => name.toUpperCase();
}

/// Nível mínimo que deve ser gravado/reportado em cada ambiente (RC-03B):
/// Development vê tudo (TRACE+); QA e Beta só a partir de INFO;
/// Production só WARNING+. Um nome de ambiente desconhecido usa o mesmo
/// piso de `production` — o mais restritivo — por segurança.
AppLogLevel minimumLevelForEnvironment(String environment) {
  switch (environment) {
    case 'development':
      return AppLogLevel.trace;
    case 'qa':
    case 'beta':
      return AppLogLevel.info;
    case 'production':
    default:
      return AppLogLevel.warning;
  }
}
