import 'package:app/features/events/application/rotation_suggestion_provider.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_details.dart';
import 'package:app/features/groups/domain/group_member.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockEventRepository extends Mock implements EventRepository {}

GroupMember _member(String userId, String name) {
  return GroupMember(
    id: 'gm-$userId',
    userId: userId,
    role: 'member',
    fullName: name,
    avatarUrl: null,
  );
}

Event _event({
  required String id,
  required String organizerId,
  required DateTime scheduledAt,
}) {
  return Event(
    id: id,
    groupId: 'g-1',
    restaurantId: 'r-1',
    organizerId: organizerId,
    scheduledAt: scheduledAt,
    status: 'completed',
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

  test('grupo com só 1 membro -> nenhuma sugestão', () async {
    when(() => groupRepository.getById('g-1')).thenAnswer(
      (_) async => GroupDetails(
        group: const Group(
          id: 'g-1',
          name: 'Grupo',
          description: null,
          photoUrl: null,
          inviteCode: 'ABCDEFGH',
        ),
        members: [_member('user-1', 'Ana')],
      ),
    );

    final result = await container.read(
      rotationSuggestionProvider('g-1').future,
    );

    expect(result, isNull);
  });

  test('membro que nunca organizou vence quem já organizou', () async {
    when(() => groupRepository.getById('g-1')).thenAnswer(
      (_) async => GroupDetails(
        group: const Group(
          id: 'g-1',
          name: 'Grupo',
          description: null,
          photoUrl: null,
          inviteCode: 'ABCDEFGH',
        ),
        members: [_member('user-1', 'Ana'), _member('user-2', 'Bruno')],
      ),
    );
    when(() => eventRepository.listByGroup('g-1')).thenAnswer(
      (_) async => [
        _event(
          id: 'e-1',
          organizerId: 'user-1',
          scheduledAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    final result = await container.read(
      rotationSuggestionProvider('g-1').future,
    );

    expect(result?.userId, 'user-2');
  });

  test(
    'quando todos já organizaram, sugere quem organizou há mais tempo',
    () async {
      when(() => groupRepository.getById('g-1')).thenAnswer(
        (_) async => GroupDetails(
          group: const Group(
            id: 'g-1',
            name: 'Grupo',
            description: null,
            photoUrl: null,
            inviteCode: 'ABCDEFGH',
          ),
          members: [_member('user-1', 'Ana'), _member('user-2', 'Bruno')],
        ),
      );
      when(() => eventRepository.listByGroup('g-1')).thenAnswer(
        (_) async => [
          _event(
            id: 'e-1',
            organizerId: 'user-1',
            scheduledAt: DateTime(2026, 1, 1),
          ),
          _event(
            id: 'e-2',
            organizerId: 'user-2',
            scheduledAt: DateTime(2026, 6, 1),
          ),
        ],
      );

      final result = await container.read(
        rotationSuggestionProvider('g-1').future,
      );

      // user-1 organizou por último em janeiro, user-2 em junho - user-1
      // está há mais tempo sem organizar, é o sugerido.
      expect(result?.userId, 'user-1');
    },
  );

  test(
    'usa a organização mais recente de cada membro, não a mais antiga',
    () async {
      when(() => groupRepository.getById('g-1')).thenAnswer(
        (_) async => GroupDetails(
          group: const Group(
            id: 'g-1',
            name: 'Grupo',
            description: null,
            photoUrl: null,
            inviteCode: 'ABCDEFGH',
          ),
          members: [_member('user-1', 'Ana'), _member('user-2', 'Bruno')],
        ),
      );
      when(() => eventRepository.listByGroup('g-1')).thenAnswer(
        (_) async => [
          // user-1 organizou em janeiro E em julho (mais recente) -
          // "última vez que organizou" deve ser julho, não janeiro.
          _event(
            id: 'e-1',
            organizerId: 'user-1',
            scheduledAt: DateTime(2026, 1, 1),
          ),
          _event(
            id: 'e-2',
            organizerId: 'user-1',
            scheduledAt: DateTime(2026, 7, 1),
          ),
          _event(
            id: 'e-3',
            organizerId: 'user-2',
            scheduledAt: DateTime(2026, 3, 1),
          ),
        ],
      );

      final result = await container.read(
        rotationSuggestionProvider('g-1').future,
      );

      // user-1: última vez em julho. user-2: última vez em março - user-2
      // está há mais tempo sem organizar, é o sugerido.
      expect(result?.userId, 'user-2');
    },
  );
}
