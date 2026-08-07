import 'package:app/features/events/application/events_list_controller.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/events/presentation/states/events_list_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

Event _event({String id = 'e-1', String restaurantName = 'Bar do Zé'}) {
  return Event(
    id: id,
    groupId: 'g-1',
    restaurantId: 'r-1',
    organizerId: 'u-organizer',
    scheduledAt: DateTime(2026, 8, 20, 20, 0),
    status: 'scheduled',
    restaurantName: restaurantName,
    restaurantCategory: 'Bar',
    restaurantCity: 'São Paulo',
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

  test('estado inicial é EventsListInitial', () {
    expect(
      container.read(eventsListControllerProvider),
      isA<EventsListInitial>(),
    );
  });

  group('load', () {
    test('lista não vazia -> EventsListLoaded', () async {
      when(() => repository.listByGroup('g-1')).thenAnswer(
        (_) async => [
          _event(id: 'e-1'),
          _event(id: 'e-2', restaurantName: 'Cantina da Vila'),
        ],
      );

      await container.read(eventsListControllerProvider.notifier).load('g-1');

      final status = container.read(eventsListControllerProvider);
      expect(status, isA<EventsListLoaded>());
      expect((status as EventsListLoaded).events, hasLength(2));
    });

    test('lista vazia -> EventsListEmpty', () async {
      when(() => repository.listByGroup('g-1')).thenAnswer((_) async => []);

      await container.read(eventsListControllerProvider.notifier).load('g-1');

      expect(
        container.read(eventsListControllerProvider),
        isA<EventsListEmpty>(),
      );
    });

    test(
      'falha com EventRepositoryException -> EventsListError com a mensagem original',
      () async {
        when(() => repository.listByGroup('g-1')).thenThrow(
          const EventRepositoryException('Você não é membro deste grupo.'),
        );

        await container.read(eventsListControllerProvider.notifier).load('g-1');

        final status = container.read(eventsListControllerProvider);
        expect(status, isA<EventsListError>());
        expect(
          (status as EventsListError).message,
          'Você não é membro deste grupo.',
        );
      },
    );

    test('falha inesperada -> EventsListError com mensagem genérica', () async {
      when(
        () => repository.listByGroup('g-1'),
      ).thenThrow(Exception('erro de rede'));

      await container.read(eventsListControllerProvider.notifier).load('g-1');

      final status = container.read(eventsListControllerProvider);
      expect(status, isA<EventsListError>());
      expect(
        (status as EventsListError).message,
        'Não foi possível carregar os rolês.',
      );
    });
  });
}
