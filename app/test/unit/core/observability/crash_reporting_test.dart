import 'package:app/core/logger/app_log_level.dart';
import 'package:app/core/observability/crash_reporting.dart';
import 'package:flutter_test/flutter_test.dart';

/// `Sentry.captureException`/`captureMessage` chamados antes de
/// `Sentry.init` fazem no-op silencioso (Hub padrão é `NoOpHub` até o SDK
/// ser inicializado - mesma premissa já usada em
/// `sentry_provider_observer_test.dart` na RC-03A). Os testes aqui
/// confirmam que `CrashReporting.captureLog` (RC-03B) não lança para
/// nenhuma combinação de nível/parâmetros - a cobertura de qual
/// `SentryLevel`/tag é de fato enviado depende do SDK do Sentry, já
/// coberta pela suíte upstream do pacote.
void main() {
  group('CrashReporting.captureLog', () {
    for (final level in AppLogLevel.values) {
      test('não lança para o nível ${level.label} sem error', () async {
        await expectLater(
          CrashReporting.captureLog(level, 'mensagem de teste'),
          completes,
        );
      });

      test(
        'não lança para o nível ${level.label} com error/stackTrace',
        () async {
          await expectLater(
            CrashReporting.captureLog(
              level,
              'mensagem de teste',
              error: Exception('falha'),
              stackTrace: StackTrace.current,
              tag: 'core/CrashReportingTest',
              userId: 'user-1',
            ),
            completes,
          );
        },
      );
    }
  });
}
