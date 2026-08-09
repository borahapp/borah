import 'package:app/features/events/application/event_review_sync_task.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

// `EventReviewSyncTask` recebe um `Ref` de verdade (não um
// `ProviderContainer`, que não implementa `Ref`) - mesmo padrão de
// qualquer outra classe do projeto construída a partir de um provider.
final _taskProvider = Provider((ref) => EventReviewSyncTask(ref));

void main() {
  late MockEventRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockEventRepository();
    container = ProviderContainer(
      overrides: [eventRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('run() delega para EventRepository.notifyReadyForReview()', () async {
    when(() => repository.notifyReadyForReview()).thenAnswer((_) async {});

    await container.read(_taskProvider).run();

    verify(() => repository.notifyReadyForReview()).called(1);
  });

  test(
    'run() propaga a exceção do repository (LazySyncDispatcher isola)',
    () async {
      when(
        () => repository.notifyReadyForReview(),
      ).thenThrow(const EventRepositoryException('Falha de rede.'));

      final task = container.read(_taskProvider);

      expect(() => task.run(), throwsA(isA<EventRepositoryException>()));
    },
  );
}
