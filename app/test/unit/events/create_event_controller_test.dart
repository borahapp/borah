import 'package:app/features/events/application/create_event_controller.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/events/presentation/states/create_event_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

Event _event() {
  return Event(
    id: 'e-1',
    groupId: 'g-1',
    restaurantId: 'r-1',
    scheduledAt: DateTime(2026, 8, 20, 20, 0),
    status: 'scheduled',
  );
}

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

  test('estado inicial é CreateEventInitial', () {
    expect(
      container.read(createEventControllerProvider),
      isA<CreateEventInitial>(),
    );
  });

  group('create', () {
    test('sucesso -> CreateEventSaveSuccess', () async {
      when(
        () => repository.create(
          groupId: any(named: 'groupId'),
          restaurantId: any(named: 'restaurantId'),
          scheduledAt: any(named: 'scheduledAt'),
        ),
      ).thenAnswer((_) async => _event());

      await container
          .read(createEventControllerProvider.notifier)
          .create(
            groupId: 'g-1',
            restaurantId: 'r-1',
            scheduledAt: DateTime(2026, 8, 20, 20, 0),
          );

      expect(
        container.read(createEventControllerProvider),
        isA<CreateEventSaveSuccess>(),
      );
    });

    test('falha com EventRepositoryException -> CreateEventError com a mensagem original', () async {
      when(
        () => repository.create(
          groupId: any(named: 'groupId'),
          restaurantId: any(named: 'restaurantId'),
          scheduledAt: any(named: 'scheduledAt'),
        ),
      ).thenThrow(const EventRepositoryException('Você não é membro deste grupo.'));

      await container
          .read(createEventControllerProvider.notifier)
          .create(
            groupId: 'g-1',
            restaurantId: 'r-1',
            scheduledAt: DateTime(2026, 8, 20, 20, 0),
          );

      final status = container.read(createEventControllerProvider);
      expect(status, isA<CreateEventError>());
      expect(
        (status as CreateEventError).message,
        'Você não é membro deste grupo.',
      );
    });

    test('falha inesperada -> CreateEventError com mensagem genérica', () async {
      when(
        () => repository.create(
          groupId: any(named: 'groupId'),
          restaurantId: any(named: 'restaurantId'),
          scheduledAt: any(named: 'scheduledAt'),
        ),
      ).thenThrow(Exception('erro de rede'));

      await container
          .read(createEventControllerProvider.notifier)
          .create(
            groupId: 'g-1',
            restaurantId: 'r-1',
            scheduledAt: DateTime(2026, 8, 20, 20, 0),
          );

      final status = container.read(createEventControllerProvider);
      expect(status, isA<CreateEventError>());
      expect(
        (status as CreateEventError).message,
        'Não foi possível criar o rolê.',
      );
    });
  });
}
