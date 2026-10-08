import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_details.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/event_summary.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/home/application/home_controller.dart';
import 'package:app/features/home/presentation/states/home_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockEventRepository extends Mock implements EventRepository {}

Group _group({
  String id = 'g-1',
  String name = 'Turma do João',
  EventSummary? nextEvent,
}) {
  return Group(
    id: id,
    name: name,
    description: null,
    photoUrl: null,
    inviteCode: 'FS575HP5',
    memberCount: 4,
    nextEvent: nextEvent,
  );
}

Event _event({
  String id = 'e-1',
  String groupId = 'g-1',
  DateTime? scheduledAt,
}) {
  return Event(
    id: id,
    groupId: groupId,
    restaurantId: 'r-1',
    organizerId: 'u-1',
    scheduledAt: scheduledAt ?? DateTime(2026, 9, 1, 20),
    status: 'scheduled',
    restaurantName: 'Madero',
    confirmedCount: 2,
  );
}

void main() {
  late MockGroupRepository groupRepository;
  late MockEventRepository eventRepository;
  late ProviderContainer container;

  setUp(() {
    groupRepository = MockGroupRepository();
    eventRepository = MockEventRepository();
    container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(groupRepository),
        eventRepositoryProvider.overrideWithValue(eventRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é HomeInitial', () {
    expect(container.read(homeControllerProvider), isA<HomeInitial>());
  });

  group('load', () {
    test(
      'sem grupos -> HomeLoaded com lista vazia e sem rolê em destaque',
      () async {
        when(() => groupRepository.listMine()).thenAnswer((_) async => []);

        await container.read(homeControllerProvider.notifier).load();

        final status = container.read(homeControllerProvider);
        expect(status, isA<HomeLoaded>());
        final loaded = status as HomeLoaded;
        expect(loaded.groups, isEmpty);
        expect(loaded.heroEvent, isNull);
        expect(loaded.heroEventGroup, isNull);
        verifyNever(() => eventRepository.getById(any()));
      },
    );

    test('grupos sem nenhum próximo rolê -> HomeLoaded sem rolê em destaque, '
        'sem chamar getById', () async {
      when(
        () => groupRepository.listMine(),
      ).thenAnswer((_) async => [_group(id: 'g-1'), _group(id: 'g-2')]);

      await container.read(homeControllerProvider.notifier).load();

      final loaded = container.read(homeControllerProvider) as HomeLoaded;
      expect(loaded.groups, hasLength(2));
      expect(loaded.heroEvent, isNull);
      verifyNever(() => eventRepository.getById(any()));
    });

    test('múltiplos grupos com próximo rolê -> escolhe o mais próximo no '
        'tempo, 1 única chamada a getById', () async {
      final farGroup = _group(
        id: 'g-far',
        name: 'Grupo distante',
        nextEvent: EventSummary(
          id: 'e-far',
          scheduledAt: DateTime(2026, 12, 25),
        ),
      );
      final nearGroup = _group(
        id: 'g-near',
        name: 'Grupo próximo',
        nextEvent: EventSummary(
          id: 'e-near',
          scheduledAt: DateTime(2026, 9, 1),
        ),
      );
      when(
        () => groupRepository.listMine(),
      ).thenAnswer((_) async => [farGroup, nearGroup]);
      when(() => eventRepository.getById('e-near')).thenAnswer(
        (_) async => EventDetails(
          event: _event(id: 'e-near', groupId: 'g-near'),
          attendances: const [],
        ),
      );

      await container.read(homeControllerProvider.notifier).load();

      final loaded = container.read(homeControllerProvider) as HomeLoaded;
      expect(loaded.heroEvent?.id, 'e-near');
      expect(loaded.heroEventGroup?.id, 'g-near');
      verify(() => eventRepository.getById('e-near')).called(1);
      verifyNever(() => eventRepository.getById('e-far'));
    });

    test(
      'falha com GroupRepositoryException -> HomeError com a mensagem original',
      () async {
        when(
          () => groupRepository.listMine(),
        ).thenThrow(const GroupRepositoryException('Falha ao carregar.'));

        await container.read(homeControllerProvider.notifier).load();

        final status = container.read(homeControllerProvider);
        expect(status, isA<HomeError>());
        expect((status as HomeError).message, 'Falha ao carregar.');
      },
    );

    test('falha com EventRepositoryException ao buscar o rolê em destaque -> '
        'HomeError com a mensagem original', () async {
      when(() => groupRepository.listMine()).thenAnswer(
        (_) async => [
          _group(
            nextEvent: EventSummary(
              id: 'e-1',
              scheduledAt: DateTime(2026, 9, 1),
            ),
          ),
        ],
      );
      when(
        () => eventRepository.getById('e-1'),
      ).thenThrow(const EventRepositoryException('Rolê não encontrado.'));

      await container.read(homeControllerProvider.notifier).load();

      final status = container.read(homeControllerProvider);
      expect(status, isA<HomeError>());
      expect((status as HomeError).message, 'Rolê não encontrado.');
    });

    test('falha inesperada -> HomeError com mensagem genérica', () async {
      when(() => groupRepository.listMine()).thenThrow(Exception('erro'));

      await container.read(homeControllerProvider.notifier).load();

      final status = container.read(homeControllerProvider);
      expect(status, isA<HomeError>());
      expect(
        (status as HomeError).message,
        'Não foi possível carregar sua Home.',
      );
    });
  });
}
