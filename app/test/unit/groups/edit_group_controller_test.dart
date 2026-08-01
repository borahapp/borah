import 'package:app/features/groups/application/edit_group_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/states/edit_group_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

Group _group({String name = 'Turma do João'}) {
  return Group(
    id: 'g-1',
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

  test('estado inicial é EditGroupInitial', () {
    expect(
      container.read(editGroupControllerProvider),
      isA<EditGroupInitial>(),
    );
  });

  group('update', () {
    test('sucesso -> EditGroupSaveSuccess', () async {
      when(
        () => repository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
        ),
      ).thenAnswer((_) async => _group(name: 'Turma Renovada'));

      await container
          .read(editGroupControllerProvider.notifier)
          .update(id: 'g-1', name: 'Turma Renovada');

      final status = container.read(editGroupControllerProvider);
      expect(status, isA<EditGroupSaveSuccess>());
      expect((status as EditGroupSaveSuccess).group.name, 'Turma Renovada');
    });

    test('falha com GroupRepositoryException -> EditGroupError com a mensagem original', () async {
      when(
        () => repository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
        ),
      ).thenThrow(const GroupRepositoryException('Apenas admin/owner pode editar o grupo.'));

      await container
          .read(editGroupControllerProvider.notifier)
          .update(id: 'g-1', name: 'Turma Renovada');

      final status = container.read(editGroupControllerProvider);
      expect(status, isA<EditGroupError>());
      expect(
        (status as EditGroupError).message,
        'Apenas admin/owner pode editar o grupo.',
      );
    });

    test('falha inesperada -> EditGroupError com mensagem genérica', () async {
      when(
        () => repository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
        ),
      ).thenThrow(Exception('erro de rede'));

      await container
          .read(editGroupControllerProvider.notifier)
          .update(id: 'g-1', name: 'Turma Renovada');

      final status = container.read(editGroupControllerProvider);
      expect(status, isA<EditGroupError>());
      expect(
        (status as EditGroupError).message,
        'Não foi possível salvar o grupo.',
      );
    });
  });
}
