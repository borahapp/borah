import 'package:app/features/groups/application/join_group_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/states/join_group_status.dart';
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

  test('estado inicial é JoinGroupInitial', () {
    expect(
      container.read(joinGroupControllerProvider),
      isA<JoinGroupInitial>(),
    );
  });

  group('join', () {
    test('sucesso -> JoinGroupSaveSuccess', () async {
      when(
        () => repository.joinByInviteCode('FS575HP5'),
      ).thenAnswer((_) async => _group());

      await container
          .read(joinGroupControllerProvider.notifier)
          .join('FS575HP5');

      final status = container.read(joinGroupControllerProvider);
      expect(status, isA<JoinGroupSaveSuccess>());
      expect((status as JoinGroupSaveSuccess).group.name, 'Turma do João');
    });

    test(
      'falha com GroupRepositoryException -> JoinGroupError com a mensagem original',
      () async {
        when(() => repository.joinByInviteCode('XXXXXXXX')).thenThrow(
          const GroupRepositoryException('Código de convite inválido.'),
        );

        await container
            .read(joinGroupControllerProvider.notifier)
            .join('XXXXXXXX');

        final status = container.read(joinGroupControllerProvider);
        expect(status, isA<JoinGroupError>());
        expect(
          (status as JoinGroupError).message,
          'Código de convite inválido.',
        );
      },
    );

    test('falha inesperada -> JoinGroupError com mensagem genérica', () async {
      when(
        () => repository.joinByInviteCode('FS575HP5'),
      ).thenThrow(Exception('erro de rede'));

      await container
          .read(joinGroupControllerProvider.notifier)
          .join('FS575HP5');

      final status = container.read(joinGroupControllerProvider);
      expect(status, isA<JoinGroupError>());
      expect(
        (status as JoinGroupError).message,
        'Não foi possível entrar no grupo.',
      );
    });
  });

  group('joinPublic', () {
    test('sucesso -> JoinGroupSaveSuccess', () async {
      when(
        () => repository.joinPublicGroup('g-1'),
      ).thenAnswer((_) async => _group());

      await container
          .read(joinGroupControllerProvider.notifier)
          .joinPublic('g-1');

      final status = container.read(joinGroupControllerProvider);
      expect(status, isA<JoinGroupSaveSuccess>());
      expect((status as JoinGroupSaveSuccess).group.name, 'Turma do João');
    });

    test(
      'grupo não é público -> JoinGroupError com a mensagem original',
      () async {
        when(() => repository.joinPublicGroup('g-2')).thenThrow(
          const GroupRepositoryException('Este grupo não é público.'),
        );

        await container
            .read(joinGroupControllerProvider.notifier)
            .joinPublic('g-2');

        final status = container.read(joinGroupControllerProvider);
        expect(status, isA<JoinGroupError>());
        expect((status as JoinGroupError).message, 'Este grupo não é público.');
      },
    );

    test('falha inesperada -> JoinGroupError com mensagem genérica', () async {
      when(
        () => repository.joinPublicGroup('g-1'),
      ).thenThrow(Exception('erro de rede'));

      await container
          .read(joinGroupControllerProvider.notifier)
          .joinPublic('g-1');

      final status = container.read(joinGroupControllerProvider);
      expect(status, isA<JoinGroupError>());
      expect(
        (status as JoinGroupError).message,
        'Não foi possível entrar no grupo.',
      );
    });
  });
}
