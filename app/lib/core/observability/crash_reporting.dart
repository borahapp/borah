import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../environment/app_environment.dart';
import '../logger/app_log_level.dart';
import 'sentry_event_sanitizer.dart';

/// Ponto único de configuração e uso do Sentry (RC-03A). Nenhum outro
/// arquivo do app deve chamar `SentryFlutter.init`/`Sentry.captureException`
/// diretamente — tudo passa por aqui, para manter a inicialização
/// centralizada (nunca espalhada, conforme exigido nesta rodada) e a
/// sanitização de privacidade sempre aplicada.
abstract final class CrashReporting {
  /// Inicializa o Sentry e roda [appRunner] dentro da zona de captura do
  /// próprio SDK. `SentryFlutter.init(appRunner: ...)` instala
  /// automaticamente `FlutterError.onError`, `PlatformDispatcher.instance
  /// .onError` e (quando a plataforma exige, ex. Web) `runZonedGuarded` —
  /// não são reimplementados manualmente aqui para evitar captura
  /// duplicada do mesmo erro.
  static Future<void> run(Future<void> Function() appRunner) {
    return SentryFlutter.init(_configure, appRunner: appRunner);
  }

  static void _configure(SentryFlutterOptions options) {
    options.dsn = AppEnvironment.sentryDsn;
    options.environment = AppEnvironment.environmentName;
    // Logs de diagnóstico do próprio SDK só em modo debug local — nunca
    // aparecem em builds de release.
    options.debug = kDebugMode;
    // Nunca envia IP/e-mail/nome de usuário automaticamente — qualquer
    // dado de usuário só entraria via `sanitizeSentryEvent`, que os
    // redige de qualquer forma.
    options.sendDefaultPii = false;
    // Captura de tela do último frame antes do crash: pode conter dados
    // sensíveis exibidos na UI — desabilitado deliberadamente.
    options.attachScreenshot = false;
    options.beforeSend = (event, hint) => sanitizeSentryEvent(event);
  }

  /// Reporta uma exceção capturada manualmente — usado pelas integrações
  /// com Riverpod ([SentryProviderObserver]) e GoRouter (`errorBuilder` do
  /// router), que não passam pela zona global do [run]. [origin] vira uma
  /// tag `origin` no Sentry, para diferenciar a fonte do erro no
  /// dashboard sem precisar abrir o stack trace.
  static Future<void> captureException(
    Object exception,
    StackTrace stackTrace, {
    required String origin,
  }) {
    return Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('origin', origin),
    );
  }

  /// Encaminha um log de nível WARNING+ ao Sentry (RC-03B) — chamado
  /// exclusivamente por `AppLogger`, nunca diretamente por telas/
  /// controllers/repositories (isso duplicaria eventos já reportados pela
  /// captura global de [run] quando o mesmo erro também propaga para lá).
  /// TRACE/DEBUG/INFO nunca chegam aqui — `AppLogger` já filtra antes de
  /// chamar. Passa pelo mesmo `beforeSend` (sanitização) que qualquer
  /// outro evento, sem exceção.
  static Future<void> captureLog(
    AppLogLevel level,
    String message, {
    String? tag,
    String? userId,
    Object? error,
    StackTrace? stackTrace,
  }) {
    void withScope(Scope scope) {
      scope.level = _toSentryLevel(level);
      scope.setTag('origin', 'app_logger');
      if (tag != null) scope.setTag('log_tag', tag);
      if (userId != null) scope.setTag('user_id', userId);
    }

    if (error != null) {
      return Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: withScope,
      );
    }
    return Sentry.captureMessage(
      message,
      level: _toSentryLevel(level),
      withScope: withScope,
    );
  }

  static SentryLevel _toSentryLevel(AppLogLevel level) => switch (level) {
    AppLogLevel.trace || AppLogLevel.debug => SentryLevel.debug,
    AppLogLevel.info => SentryLevel.info,
    AppLogLevel.warning => SentryLevel.warning,
    AppLogLevel.error => SentryLevel.error,
    AppLogLevel.fatal => SentryLevel.fatal,
  };
}
