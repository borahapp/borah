import 'dart:developer' as developer;

import 'package:meta/meta.dart';

import '../environment/app_environment.dart';
import '../observability/crash_reporting.dart';
import 'app_log_level.dart';

/// Sistema centralizado de logging do BORAH (RC-03B). Todo log do app deve
/// passar por aqui — nenhum `print()`/`debugPrint()` em código de produção
/// (ver `docs/FASE 9 - Execution/RC-03B_STRUCTURED_LOGGING.md` para a
/// convenção de uso e exemplos).
///
/// TRACE/DEBUG/INFO ficam só locais (`dart:developer.log`). WARNING/
/// ERROR/FATAL também são encaminhados ao Sentry via
/// [CrashReporting.captureLog] (RC-03A) — nunca chame `CrashReporting`
/// diretamente fora daqui, para manter um único ponto de decisão sobre o
/// que sai do dispositivo.
///
/// Importante: `warning`/`error`/`fatal` aqui são para erros **já
/// tratados** (capturados localmente, que não vão propagar). Um erro que
/// ainda vai ser relançado e chegar à captura global do `CrashReporting.run`,
/// ao `SentryProviderObserver` ou ao `errorBuilder` do GoRouter (RC-03A)
/// não deve *também* ser logado aqui com o mesmo `error`/`stackTrace` —
/// isso geraria um evento duplicado no Sentry.
abstract final class AppLogger {
  /// Sobrescreve o nível mínimo em testes (`test/`). `null` restaura o
  /// valor derivado do ambiente real (`AppEnvironment.environmentName`).
  /// Nunca deve ser usado em código de produção.
  @visibleForTesting
  static AppLogLevel? debugMinimumLevelOverride;

  /// Sobrescreve o destino local em testes, no lugar de `dart:developer.log`.
  @visibleForTesting
  static void Function(
    String formatted, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  })?
  debugLocalSinkOverride;

  /// Sobrescreve o encaminhamento ao Sentry em testes, no lugar de
  /// [CrashReporting.captureLog].
  @visibleForTesting
  static Future<void> Function(
    AppLogLevel level,
    String message, {
    String? tag,
    String? userId,
    Object? error,
    StackTrace? stackTrace,
  })?
  debugCrashReportingSinkOverride;

  static final AppLogLevel _environmentMinimumLevel =
      minimumLevelForEnvironment(AppEnvironment.environmentName);

  static AppLogLevel get _minimumLevel =>
      debugMinimumLevelOverride ?? _environmentMinimumLevel;

  /// `true` se [level] seria gravado localmente no ambiente atual (ou no
  /// override de teste) — permite inspecionar o comportamento por
  /// ambiente sem precisar interceptar a saída de `dart:developer.log`.
  static bool isLevelEnabled(AppLogLevel level) =>
      level.index >= _minimumLevel.index;

  static void trace(String message, {String? tag, String? userId}) =>
      _log(AppLogLevel.trace, message, tag: tag, userId: userId);

  static void debug(String message, {String? tag, String? userId}) =>
      _log(AppLogLevel.debug, message, tag: tag, userId: userId);

  static void info(String message, {String? tag, String? userId}) =>
      _log(AppLogLevel.info, message, tag: tag, userId: userId);

  static void warning(
    String message, {
    String? tag,
    String? userId,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    AppLogLevel.warning,
    message,
    tag: tag,
    userId: userId,
    error: error,
    stackTrace: stackTrace,
  );

  static void error(
    String message, {
    String? tag,
    String? userId,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    AppLogLevel.error,
    message,
    tag: tag,
    userId: userId,
    error: error,
    stackTrace: stackTrace,
  );

  static void fatal(
    String message, {
    String? tag,
    String? userId,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    AppLogLevel.fatal,
    message,
    tag: tag,
    userId: userId,
    error: error,
    stackTrace: stackTrace,
  );

  static void _log(
    AppLogLevel level,
    String message, {
    String? tag,
    String? userId,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!isLevelEnabled(level)) return;

    final formatted = _format(
      level,
      DateTime.now().toUtc(),
      tag,
      userId,
      message,
    );

    final localSink = debugLocalSinkOverride ?? _defaultLocalSink;
    localSink(
      formatted,
      level: level.developerLogLevel,
      error: error,
      stackTrace: stackTrace,
    );

    // Só WARNING+ chega ao Sentry - TRACE/DEBUG/INFO nunca saem do
    // dispositivo (RC-03B). A sanitização de privacidade acontece uma
    // única vez, no `beforeSend` já registrado por `CrashReporting.run`
    // (RC-03A) - não é duplicada aqui.
    if (level.index >= AppLogLevel.warning.index) {
      final crashSink =
          debugCrashReportingSinkOverride ?? CrashReporting.captureLog;
      crashSink(
        level,
        message,
        tag: tag,
        userId: userId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void _defaultLocalSink(
    String formatted, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      formatted,
      name: 'BORAH',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Formato: `[NÍVEL] timestamp tag user=userId — mensagem`. `tag` segue
  /// a convenção `feature/Classe.metodo` (ex.: `reviews/
  /// ReviewDetailController.addPhoto`) - ver RC-03B_STRUCTURED_LOGGING.md.
  static String _format(
    AppLogLevel level,
    DateTime timestamp,
    String? tag,
    String? userId,
    String message,
  ) {
    final buffer = StringBuffer(
      '[${level.label}] ${timestamp.toIso8601String()}',
    );
    if (tag != null) buffer.write(' $tag');
    if (userId != null) buffer.write(' user=$userId');
    buffer.write(' — $message');
    return buffer.toString();
  }
}
