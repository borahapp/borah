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
        id: 'm-1',
        userId: 'u-1',
        role: 'owner',
        fullName: 'Ana Silva',
        avatarUrl: null,
      ),
      GroupMember(
        id: 'm-2',
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

    test(
      'falha com GroupRepositoryException -> GroupDetailError com a mensagem original',
      () async {
        when(
          () => repository.getById('g-1'),
        ).thenThrow(const GroupRepositoryException('Grupo não encontrado.'));

        await container
            .read(groupDetailControllerProvider.notifier)
            .load('g-1');

        final status = container.read(groupDetailControllerProvider);
        expect(status, isA<GroupDetailError>());
        expect((status as GroupDetailError).message, 'Grupo não encontrado.');
      },
    );

    test(
      'falha inesperada -> GroupDetailError com mensagem genérica',
      () async {
        when(
          () => repository.getById('g-1'),
        ).thenThrow(Exception('erro de rede'));

        await container
            .read(groupDetailControllerProvider.notifier)
            .load('g-1');

        final status = container.read(groupDetailControllerProvider);
        expect(status, isA<GroupDetailError>());
        expect(
          (status as GroupDetailError).message,
          'Não foi possível carregar o grupo.',
        );
      },
    );
  });

  group('buildInviteShareMessage', () {
    test('sem grupo carregado -> null', () {
      final message = container
          .read(groupDetailControllerProvider.notifier)
          .buildInviteShareMessage();
      expect(message, isNull);
    });

    test(
      'com grupo carregado -> mensagem contém nome e código do convite',
      () async {
        when(
          () => repository.getById('g-1'),
        ).thenAnswer((_) async => _details());
        await container
            .read(groupDetailControllerProvider.notifier)
            .load('g-1');

        final message = container
            .read(groupDetailControllerProvider.notifier)
            .buildInviteShareMessage();

        expect(message, isNotNull);
        expect(message, contains('Turma do João'));
        expect(message, contains('FS575HP5'));
        // Deep Link de convite (core/deep_link/) - quem já tem o app
        // entra direto, sem digitar o código.
        expect(message, contains('borah://group/join?invite=FS575HP5'));
      },
    );
  });

  group('promoteToAdmin/demoteToMember/removeMember', () {
    test('promoteToAdmin com sucesso -> recarrega o grupo', () async {
      when(() => repository.getById('g-1')).thenAnswer((_) async => _details());
      when(
        () => repository.updateMemberRole(memberId: 'm-2', role: 'admin'),
      ).thenAnswer((_) async {});

      final notifier = container.read(groupDetailControllerProvider.notifier);
      await notifier.load('g-1');
      await notifier.promoteToAdmin('m-2');

      verify(() => repository.getById('g-1')).called(2);
      expect(
        container.read(groupDetailControllerProvider),
        isA<GroupDetailLoaded>(),
      );
    });

    test(
      'removeMember falha -> GroupDetailError com o grupo ainda carregado',
      () async {
        when(
          () => repository.getById('g-1'),
        ).thenAnswer((_) async => _details());
        when(() => repository.removeMember('m-2')).thenThrow(
          const GroupRepositoryException(
            'Apenas admin/owner pode remover membros.',
          ),
        );

        final notifier = container.read(groupDetailControllerProvider.notifier);
        await notifier.load('g-1');
        await notifier.removeMember('m-2');

        final status = container.read(groupDetailControllerProvider);
        expect(status, isA<GroupDetailError>());
        expect(
          (status as GroupDetailError).message,
          'Apenas admin/owner pode remover membros.',
        );
        expect(status.details, isNotNull);
        expect(status.details!.members, hasLength(2));
      },
    );

    test('sem grupo carregado -> não chama o repository', () async {
      await container
          .read(groupDetailControllerProvider.notifier)
          .promoteToAdmin('m-2');

      verifyNever(
        () => repository.updateMemberRole(
          memberId: any(named: 'memberId'),
          role: any(named: 'role'),
        ),
      );
    });
  });

  group('leaveGroup', () {
    test('delega direto ao repository (sem estado próprio)', () async {
      when(() => repository.removeMember('m-2')).thenAnswer((_) async {});

      await container
          .read(groupDetailControllerProvider.notifier)
          .leaveGroup('m-2');

      verify(() => repository.removeMember('m-2')).called(1);
    });
  });

  group('transferOwnership', () {
    test('sucesso -> chama o repository e recarrega o grupo', () async {
      when(() => repository.getById('g-1')).thenAnswer((_) async => _details());
      when(
        () => repository.transferOwnership(
          groupId: 'g-1',
          newOwnerMemberId: 'm-2',
        ),
      ).thenAnswer((_) async {});

      final notifier = container.read(groupDetailControllerProvider.notifier);
      await notifier.load('g-1');
      await notifier.transferOwnership('m-2');

      verify(
        () => repository.transferOwnership(
          groupId: 'g-1',
          newOwnerMemberId: 'm-2',
        ),
      ).called(1);
      verify(() => repository.getById('g-1')).called(2);
      expect(
        container.read(groupDetailControllerProvider),
        isA<GroupDetailLoaded>(),
      );
    });

    test('falha -> GroupDetailError com o grupo ainda carregado', () async {
      when(() => repository.getById('g-1')).thenAnswer((_) async => _details());
      when(
        () => repository.transferOwnership(
          groupId: 'g-1',
          newOwnerMemberId: 'm-2',
        ),
      ).thenThrow(
        const GroupRepositoryException(
          'Apenas o proprietário do grupo pode transferir a propriedade.',
        ),
      );

      final notifier = container.read(groupDetailControllerProvider.notifier);
      await notifier.load('g-1');
      await notifier.transferOwnership('m-2');

      final status = container.read(groupDetailControllerProvider);
      expect(status, isA<GroupDetailError>());
      expect(
        (status as GroupDetailError).message,
        'Apenas o proprietário do grupo pode transferir a propriedade.',
      );
      expect(status.details, isNotNull);
      expect(status.details!.members, hasLength(2));
    });

    test('sem grupo carregado -> não chama o repository', () async {
      await container
          .read(groupDetailControllerProvider.notifier)
          .transferOwnership('m-2');

      verifyNever(
        () => repository.transferOwnership(
          groupId: any(named: 'groupId'),
          newOwnerMemberId: any(named: 'newOwnerMemberId'),
        ),
      );
    });
  });

  group('deleteGroup', () {
    test('sucesso -> delega direto ao repository (sem recarregar)', () async {
      when(() => repository.getById('g-1')).thenAnswer((_) async => _details());
      when(() => repository.delete('g-1')).thenAnswer((_) async {});

      final notifier = container.read(groupDetailControllerProvider.notifier);
      await notifier.load('g-1');
      await notifier.deleteGroup();

      verify(() => repository.delete('g-1')).called(1);
      // Não recarrega - `getById` continua tendo sido chamado só 1 vez
      // (o `load()` inicial), diferente de `transferOwnership`, que
      // chama de novo após o sucesso.
      verify(() => repository.getById('g-1')).called(1);
    });

    test('falha -> propaga a exceção (mesmo padrão de leaveGroup)', () async {
      when(() => repository.getById('g-1')).thenAnswer((_) async => _details());
      when(() => repository.delete('g-1')).thenThrow(
        const GroupRepositoryException('Não foi possível excluir o grupo.'),
      );

      final notifier = container.read(groupDetailControllerProvider.notifier);
      await notifier.load('g-1');

      expect(
        () => notifier.deleteGroup(),
        throwsA(isA<GroupRepositoryException>()),
      );
    });

    test('sem grupo carregado -> não chama o repository', () async {
      await container
          .read(groupDetailControllerProvider.notifier)
          .deleteGroup();

      verifyNever(() => repository.delete(any()));
    });
  });
}
