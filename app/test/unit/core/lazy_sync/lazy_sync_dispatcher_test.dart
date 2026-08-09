import 'package:app/core/lazy_sync/lazy_sync_dispatcher.dart';
import 'package:app/core/lazy_sync/lazy_sync_task.dart';
import 'package:app/core/logger/app_log_level.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingTask implements LazySyncTask {
  int callCount = 0;

  @override
  Future<void> run() async {
    callCount++;
  }
}

class _ThrowingTask implements LazySyncTask {
  @override
  Future<void> run() => throw StateError('falha proposital');
}

void main() {
  final localCalls = <Map<String, dynamic>>[];

  setUp(() {
    localCalls.clear();
    AppLogger.debugMinimumLevelOverride = AppLogLevel.trace;
    AppLogger.debugLocalSinkOverride =
        (formatted, {required level, error, stackTrace}) {
          localCalls.add({'formatted': formatted, 'level': level});
        };
    AppLogger.debugCrashReportingSinkOverride =
        (level, message, {tag, userId, error, stackTrace}) async {};
  });

  tearDown(() {
    AppLogger.debugMinimumLevelOverride = null;
    AppLogger.debugLocalSinkOverride = null;
    AppLogger.debugCrashReportingSinkOverride = null;
  });

  test('runAll() executa todas as tarefas registradas', () async {
    final taskA = _RecordingTask();
    final taskB = _RecordingTask();
    final dispatcher = LazySyncDispatcher(tasks: [taskA, taskB]);

    await dispatcher.runAll();

    expect(taskA.callCount, 1);
    expect(taskB.callCount, 1);
  });

  test('exceção de uma tarefa não impede as demais de rodar', () async {
    final before = _RecordingTask();
    final throwing = _ThrowingTask();
    final after = _RecordingTask();
    final dispatcher = LazySyncDispatcher(tasks: [before, throwing, after]);

    await dispatcher.runAll();

    expect(before.callCount, 1);
    expect(after.callCount, 1);
    expect(
      localCalls.any(
        (c) => (c['formatted'] as String).contains('LazySyncTask'),
      ),
      isTrue,
    );
  });

  test(
    'aceita Iterable (não só List) e copia para uma coleção imutável no construtor',
    () async {
      final tasks = [_RecordingTask(), _RecordingTask()];
      final dispatcher = LazySyncDispatcher(tasks: tasks.map((t) => t));

      final addedLate = _RecordingTask();
      tasks.add(addedLate);

      await dispatcher.runAll();

      expect(tasks[0].callCount, 1);
      expect(tasks[1].callCount, 1);
      expect(addedLate.callCount, 0);
    },
  );

  test('runAll() sem nenhuma tarefa registrada não lança', () async {
    final dispatcher = LazySyncDispatcher(tasks: const []);

    await dispatcher.runAll();

    expect(localCalls, isEmpty);
  });
}
