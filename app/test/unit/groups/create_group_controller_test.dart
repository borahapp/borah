import 'package:app/features/groups/application/create_group_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/states/create_group_status.dart';
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

  test('estado inicial é CreateGroupInitial', () {
    expect(
      container.read(createGroupControllerProvider),
      isA<CreateGroupInitial>(),
    );
  });

  group('create', () {
    test('sem visibility explícito, propaga o default private', () async {
      when(
        () => repository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
          visibility: any(named: 'visibility'),
        ),
      ).thenAnswer((_) async => _group());

      await container
          .read(createGroupControllerProvider.notifier)
          .create(name: 'Turma do João');

      final captured = verify(
        () => repository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
          visibility: captureAny(named: 'visibility'),
        ),
      ).captured;
      expect(captured.single, 'private');
    });

    test('propaga visibility public quando informado', () async {
      when(
        () => repository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
          visibility: any(named: 'visibility'),
        ),
      ).thenAnswer((_) async => _group());

      await container
          .read(createGroupControllerProvider.notifier)
          .create(name: 'Turma do João', visibility: 'public');

      final captured = verify(
        () => repository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
          visibility: captureAny(named: 'visibility'),
        ),
      ).captured;
      expect(captured.single, 'public');
    });

    test('sucesso -> CreateGroupSaveSuccess', () async {
      when(
        () => repository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
          visibility: any(named: 'visibility'),
        ),
      ).thenAnswer((_) async => _group());

      await container
          .read(createGroupControllerProvider.notifier)
          .create(name: 'Turma do João');

      expect(
        container.read(createGroupControllerProvider),
        isA<CreateGroupSaveSuccess>(),
      );
    });

    test(
      'falha com GroupRepositoryException -> CreateGroupError com a mensagem original',
      () async {
        when(
          () => repository.create(
            name: any(named: 'name'),
            description: any(named: 'description'),
            photoUrl: any(named: 'photoUrl'),
          ),
        ).thenThrow(const GroupRepositoryException('Nome inválido.'));

        await container
            .read(createGroupControllerProvider.notifier)
            .create(name: '   ');

        final status = container.read(createGroupControllerProvider);
        expect(status, isA<CreateGroupError>());
        expect((status as CreateGroupError).message, 'Nome inválido.');
      },
    );

    test(
      'falha inesperada -> CreateGroupError com mensagem genérica',
      () async {
        when(
          () => repository.create(
            name: any(named: 'name'),
            description: any(named: 'description'),
            photoUrl: any(named: 'photoUrl'),
          ),
        ).thenThrow(Exception('erro de rede'));

        await container
            .read(createGroupControllerProvider.notifier)
            .create(name: 'Turma do João');

        final status = container.read(createGroupControllerProvider);
        expect(status, isA<CreateGroupError>());
        expect(
          (status as CreateGroupError).message,
          'Não foi possível criar o grupo.',
        );
      },
    );
  });
}
