import 'package:app/core/logger/app_log_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('minimumLevelForEnvironment', () {
    test('development -> TRACE (tudo aparece)', () {
      expect(minimumLevelForEnvironment('development'), AppLogLevel.trace);
    });

    test('qa -> INFO', () {
      expect(minimumLevelForEnvironment('qa'), AppLogLevel.info);
    });

    test('beta -> INFO', () {
      expect(minimumLevelForEnvironment('beta'), AppLogLevel.info);
    });

    test('production -> WARNING', () {
      expect(minimumLevelForEnvironment('production'), AppLogLevel.warning);
    });

    test('ambiente desconhecido -> WARNING (mesmo piso de production)', () {
      expect(minimumLevelForEnvironment('staging'), AppLogLevel.warning);
      expect(minimumLevelForEnvironment(''), AppLogLevel.warning);
    });
  });

  test('ordem de severidade dos níveis é crescente', () {
    expect(AppLogLevel.trace.index, lessThan(AppLogLevel.debug.index));
    expect(AppLogLevel.debug.index, lessThan(AppLogLevel.info.index));
    expect(AppLogLevel.info.index, lessThan(AppLogLevel.warning.index));
    expect(AppLogLevel.warning.index, lessThan(AppLogLevel.error.index));
    expect(AppLogLevel.error.index, lessThan(AppLogLevel.fatal.index));
  });

  test('label é o nome do nível em maiúsculas', () {
    expect(AppLogLevel.trace.label, 'TRACE');
    expect(AppLogLevel.warning.label, 'WARNING');
    expect(AppLogLevel.fatal.label, 'FATAL');
  });
}
