import 'package:app/features/groups/application/group_detail_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_details.dart';
import 'package:app/features/groups/domain/group_member.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/states/group_detail_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

GroupDetails _details() {
  return const GroupDetails(
    group: Group(
      id: 'g-1',
      name: 'Turma do João',
      description: 'Rolês de sexta',
      photoUrl: null,
      inviteCode: 'FS575HP5',
    ),
    members: [
      GroupMember(
        userId: 'u-1',
        role: 'owner',
        fullName: 'Ana Silva',
        avatarUrl: null,
      ),
      GroupMember(
        userId: 'u-2',
        role: 'member',
        fullName: 'Bruno Costa',
        avatarUrl: null,
      ),
    ],
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

  test('estado inicial é GroupDetailInitial', () {
    expect(
      container.read(groupDetailControllerProvider),
      isA<GroupDetailInitial>(),
    );
  });

  group('load', () {
    test('sucesso -> GroupDetailLoaded', () async {
      when(() => repository.getById('g-1')).thenAnswer((_) async => _details());

      await container.read(groupDetailControllerProvider.notifier).load('g-1');

      final status = container.read(groupDetailControllerProvider);
      expect(status, isA<GroupDetailLoaded>());
      expect((status as GroupDetailLoaded).details.members, hasLength(2));
    });

    test('falha com GroupRepositoryException -> GroupDetailError com a mensagem original', () async {
      when(
        () => repository.getById('g-1'),
      ).thenThrow(const GroupRepositoryException('Grupo não encontrado.'));

      await container.read(groupDetailControllerProvider.notifier).load('g-1');

      final status = container.read(groupDetailControllerProvider);
      expect(status, isA<GroupDetailError>());
      expect((status as GroupDetailError).message, 'Grupo não encontrado.');
    });

    test('falha inesperada -> GroupDetailError com mensagem genérica', () async {
      when(() => repository.getById('g-1')).thenThrow(Exception('erro de rede'));

      await container.read(groupDetailControllerProvider.notifier).load('g-1');

      final status = container.read(groupDetailControllerProvider);
      expect(status, isA<GroupDetailError>());
      expect(
        (status as GroupDetailError).message,
        'Não foi possível carregar o grupo.',
      );
    });
  });

  group('buildInviteShareMessage', () {
    test('sem grupo carregado -> null', () {
      final message = container
          .read(groupDetailControllerProvider.notifier)
          .buildInviteShareMessage();
      expect(message, isNull);
    });

    test('com grupo carregado -> mensagem contém nome e código do convite', () async {
      when(() => repository.getById('g-1')).thenAnswer((_) async => _details());
      await container.read(groupDetailControllerProvider.notifier).load('g-1');

      final message = container
          .read(groupDetailControllerProvider.notifier)
          .buildInviteShareMessage();

      expect(message, isNotNull);
      expect(message, contains('Turma do João'));
      expect(message, contains('FS575HP5'));
    });
  });
}
