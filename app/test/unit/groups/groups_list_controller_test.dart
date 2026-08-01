import 'package:app/features/groups/application/groups_list_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/states/groups_list_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

Group _group({String id = 'g-1', String name = 'Turma do João'}) {
  return Group(
    id: id,
    name: name,
    description: null,
    photoUrl: null,
    inviteCode: 'FS575HP5',
  );
}

void main() {
  late MockGroupRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockGroupRepository();
    container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é GroupsListInitial', () {
    expect(
      container.read(groupsListControllerProvider),
      isA<GroupsListInitial>(),
    );
  });

  group('load', () {
    test('lista não vazia -> GroupsListLoaded', () async {
      when(() => repository.listMine()).thenAnswer(
        (_) async => [_group(id: 'g-1'), _group(id: 'g-2', name: 'Família')],
      );

      await container.read(groupsListControllerProvider.notifier).load();

      final status = container.read(groupsListControllerProvider);
      expect(status, isA<GroupsListLoaded>());
      expect((status as GroupsListLoaded).groups, hasLength(2));
    });

    test('lista vazia -> GroupsListEmpty', () async {
      when(() => repository.listMine()).thenAnswer((_) async => []);

      await container.read(groupsListControllerProvider.notifier).load();

      expect(
        container.read(groupsListControllerProvider),
        isA<GroupsListEmpty>(),
      );
    });

    test(
      'falha com GroupRepositoryException -> GroupsListError com a mensagem original',
      () async {
        when(
          () => repository.listMine(),
        ).thenThrow(const GroupRepositoryException('Falha ao carregar.'));

        await container.read(groupsListControllerProvider.notifier).load();

        final status = container.read(groupsListControllerProvider);
        expect(status, isA<GroupsListError>());
        expect((status as GroupsListError).message, 'Falha ao carregar.');
      },
    );

    test('falha inesperada -> GroupsListError com mensagem genérica', () async {
      when(() => repository.listMine()).thenThrow(Exception('erro de rede'));

      await container.read(groupsListControllerProvider.notifier).load();

      final status = container.read(groupsListControllerProvider);
      expect(status, isA<GroupsListError>());
      expect(
        (status as GroupsListError).message,
        'Não foi possível carregar seus grupos.',
      );
    });
  });
}
