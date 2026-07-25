import 'package:app/core/logger/app_log_level.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final localCalls = <Map<String, dynamic>>[];
  final crashCalls = <Map<String, dynamic>>[];

  setUp(() {
    localCalls.clear();
    crashCalls.clear();
    AppLogger.debugLocalSinkOverride =
        (formatted, {required level, error, stackTrace}) {
          localCalls.add({
            'formatted': formatted,
            'level': level,
            'error': error,
            'stackTrace': stackTrace,
          });
        };
    AppLogger.debugCrashReportingSinkOverride =
        (level, message, {tag, userId, error, stackTrace}) async {
          crashCalls.add({
            'level': level,
            'message': message,
            'tag': tag,
            'userId': userId,
            'error': error,
            'stackTrace': stackTrace,
          });
        };
  });

  tearDown(() {
    AppLogger.debugMinimumLevelOverride = null;
    AppLogger.debugLocalSinkOverride = null;
    AppLogger.debugCrashReportingSinkOverride = null;
  });

  group('gating por ambiente (via debugMinimumLevelOverride)', () {
    test('piso TRACE (development): todos os 6 níveis logam localmente', () {
      AppLogger.debugMinimumLevelOverride = AppLogLevel.trace;

      AppLogger.trace('t');
      AppLogger.debug('d');
      AppLogger.info('i');
      AppLogger.warning('w');
      AppLogger.error('e');
      AppLogger.fatal('f');

      expect(localCalls, hasLength(6));
    });

    test('piso INFO (qa/beta): TRACE e DEBUG não logam localmente', () {
      AppLogger.debugMinimumLevelOverride = AppLogLevel.info;

      AppLogger.trace('t');
      AppLogger.debug('d');
      AppLogger.info('i');
      AppLogger.warning('w');

      expect(localCalls, hasLength(2));
    });

    test('piso WARNING (production): só WARNING+ logam localmente', () {
      AppLogger.debugMinimumLevelOverride = AppLogLevel.warning;

      AppLogger.trace('t');
      AppLogger.debug('d');
      AppLogger.info('i');
      AppLogger.warning('w');
      AppLogger.error('e');
      AppLogger.fatal('f');

      expect(localCalls, hasLength(3));
    });
  });

  group('integração com Sentry (RC-03A)', () {
    setUp(() {
      // Habilita tudo localmente para isolar este grupo da gating por
      // ambiente (já coberta acima) e focar no encaminhamento ao Sentry.
      AppLogger.debugMinimumLevelOverride = AppLogLevel.trace;
    });

    test('TRACE/DEBUG/INFO nunca chegam ao Sentry', () {
      AppLogger.trace('t');
      AppLogger.debug('d');
      AppLogger.info('i');

      expect(crashCalls, isEmpty);
    });

    test('WARNING/ERROR/FATAL chegam ao Sentry exatamente uma vez cada', () {
      AppLogger.warning('w');
      AppLogger.error('e');
      AppLogger.fatal('f');

      expect(crashCalls, hasLength(3));
      expect(crashCalls.map((c) => c['level']), [
        AppLogLevel.warning,
        AppLogLevel.error,
        AppLogLevel.fatal,
      ]);
    });

    test('nível abaixo do mínimo não gera log local nem evento no Sentry', () {
      AppLogger.debugMinimumLevelOverride = AppLogLevel.warning;

      AppLogger.info('i');

      expect(localCalls, isEmpty);
      expect(crashCalls, isEmpty);
    });
  });

  group('conteúdo repassado (sem sanitização duplicada)', () {
    setUp(() {
      AppLogger.debugMinimumLevelOverride = AppLogLevel.trace;
    });

    test('tag e userId aparecem no log local formatado', () {
      AppLogger.info(
        'mensagem',
        tag: 'reviews/ReviewDetailController.load',
        userId: 'user-1',
      );

      final formatted = localCalls.single['formatted'] as String;
      expect(formatted, contains('[INFO]'));
      expect(formatted, contains('reviews/ReviewDetailController.load'));
      expect(formatted, contains('user=user-1'));
      expect(formatted, contains('mensagem'));
    });

    test('error/stackTrace chegam intactos ao encaminhamento para o Sentry - '
        'a sanitização acontece uma única vez, no beforeSend do '
        'CrashReporting (RC-03A), nunca duplicada aqui', () {
      final exception = Exception('token=eyJhbGciOiJIUzI1NiJ9.abc.def');
      final stackTrace = StackTrace.current;

      AppLogger.error(
        'falha',
        error: exception,
        stackTrace: stackTrace,
        tag: 'auth/AuthController.signIn',
      );

      final call = crashCalls.single;
      expect(call['error'], same(exception));
      expect(call['stackTrace'], same(stackTrace));
      expect(call['tag'], 'auth/AuthController.signIn');
      expect(call['message'], 'falha');
    });

    test('sem error explícito, WARNING+ ainda é encaminhado como mensagem', () {
      AppLogger.warning('aviso sem exceção anexada');

      final call = crashCalls.single;
      expect(call['error'], isNull);
      expect(call['message'], 'aviso sem exceção anexada');
    });
  });

  test('isLevelEnabled reflete o piso efetivo (ambiente ou override)', () {
    AppLogger.debugMinimumLevelOverride = AppLogLevel.warning;

    expect(AppLogger.isLevelEnabled(AppLogLevel.info), isFalse);
    expect(AppLogger.isLevelEnabled(AppLogLevel.warning), isTrue);
    expect(AppLogger.isLevelEnabled(AppLogLevel.fatal), isTrue);
  });
}
