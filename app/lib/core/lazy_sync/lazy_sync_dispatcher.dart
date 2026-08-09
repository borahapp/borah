import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logger/app_logger.dart';
import 'lazy_sync_task.dart';

/// Executa todas as [LazySyncTask] registradas, uma a uma - mesmo
/// contrato de isolamento de `DeepLinkDispatcher` (core/deep_link/):
/// uma exceção lançada por qualquer tarefa nunca impede as demais de
/// rodar. Diferente de `DeepLinkDispatcher` (que reage a um `Stream` e
/// vive por toda a execução do app), este dispatcher não tem estado
/// nem ciclo de vida próprio - [runAll] é chamada sob demanda, a
/// qualquer momento, de qualquer lugar que decida "agora é uma boa hora
/// de sincronizar" (hoje, só `SplashPage`).
class LazySyncDispatcher {
  LazySyncDispatcher({required Iterable<LazySyncTask> tasks})
    : _tasks = List.unmodifiable(tasks);

  final List<LazySyncTask> _tasks;

  Future<void> runAll() async {
    for (final task in _tasks) {
      try {
        await task.run();
      } catch (e, stackTrace) {
        AppLogger.warning(
          'LazySyncTask (${task.runtimeType}) falhou - as demais tarefas '
          'continuam rodando normalmente.',
          tag: 'lazy_sync/LazySyncDispatcher',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }
}

/// "Seam" de injeção - a lista real de tarefas é definida via
/// `overrideWith` no bootstrap do app (`main.dart`), nunca aqui: este
/// módulo (`core/lazy_sync/`) nunca importa nenhuma feature, mesmo
/// padrão de `deepLinkReceiversProvider`. Vazio por padrão para que
/// [lazySyncDispatcherProvider] continue funcionando mesmo sem override
/// (ex.: em testes que não precisam de nenhuma tarefa real).
final lazySyncTasksProvider = Provider<List<LazySyncTask>>((ref) => const []);

final lazySyncDispatcherProvider = Provider<LazySyncDispatcher>((ref) {
  return LazySyncDispatcher(tasks: ref.watch(lazySyncTasksProvider));
});
