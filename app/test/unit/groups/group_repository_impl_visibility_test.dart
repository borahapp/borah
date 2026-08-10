import 'package:app/features/groups/data/group_remote_datasource.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRemoteDatasource extends Mock implements GroupRemoteDatasource {}

Map<String, dynamic> _row({
  String id = 'g-1',
  String name = 'Os Exploradores',
  String visibility = 'public',
  int memberCount = 5,
}) {
  return {
    'id': id,
    'name': name,
    'description': null,
    'photo_url': null,
    'invite_code': 'ABCDEFGH',
    'visibility': visibility,
    'member_count': memberCount,
  };
}

void main() {
  late MockGroupRemoteDatasource datasource;
  late GroupRepositoryImpl repository;

  setUp(() {
    datasource = MockGroupRemoteDatasource();
    repository = GroupRepositoryImpl(datasource);
  });

  group('create', () {
    test('propaga visibility para o datasource', () async {
      when(
        () => datasource.createGroup(
          name: 'Turma',
          description: null,
          photoUrl: null,
          visibility: 'public',
        ),
      ).thenAnswer((_) async => _row());

      final group = await repository.create(
        name: 'Turma',
        visibility: 'public',
      );

      expect(group.visibility, 'public');
      expect(group.isPublic, isTrue);
    });

    test('default private quando visibility não é informado', () async {
      when(
        () => datasource.createGroup(
          name: 'Turma',
          description: null,
          photoUrl: null,
          visibility: 'private',
        ),
      ).thenAnswer((_) async => _row(visibility: 'private'));

      final group = await repository.create(name: 'Turma');

      expect(group.visibility, 'private');
      expect(group.isPublic, isFalse);
    });
  });

  group('search', () {
    test('mapeia resultados com paginação', () async {
      when(
        () => datasource.searchGroups('explor', page: 1, limit: 2),
      ).thenAnswer(
        (_) async => [_row(id: 'g-1'), _row(id: 'g-2'), _row(id: 'g-3')],
      );

      final result = await repository.search('explor', page: 1, limit: 2);

      expect(result.items, hasLength(2));
      expect(result.hasNextPage, isTrue);
    });
  });

  group('listFeatured', () {
    test('mapeia resultados com paginação', () async {
      when(
        () => datasource.listFeaturedGroups(page: 1, limit: 10),
      ).thenAnswer((_) async => [_row()]);

      final result = await repository.listFeatured(page: 1, limit: 10);

      expect(result.items, hasLength(1));
      expect(result.hasNextPage, isFalse);
    });
  });

  group('getPublicSummary', () {
    test('mapeia a linha do grupo', () async {
      when(
        () => datasource.fetchGroupPublicSummary('g-1'),
      ).thenAnswer((_) async => _row());

      final group = await repository.getPublicSummary('g-1');

      expect(group.id, 'g-1');
      expect(group.memberCount, 5);
    });
  });

  group('joinPublicGroup', () {
    test('retorna o grupo em caso de sucesso', () async {
      when(
        () => datasource.joinPublicGroup('g-1'),
      ).thenAnswer((_) async => _row());

      final group = await repository.joinPublicGroup('g-1');

      expect(group.id, 'g-1');
    });
  });

  group('listMyGroupIds', () {
    test('devolve como Set', () async {
      when(
        () => datasource.fetchMyGroupIds('user-1'),
      ).thenAnswer((_) async => ['g-1', 'g-2']);

      final ids = await repository.listMyGroupIds('user-1');

      expect(ids, {'g-1', 'g-2'});
    });
  });
}
