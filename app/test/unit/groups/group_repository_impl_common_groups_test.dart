import 'package:app/features/groups/data/group_remote_datasource.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRemoteDatasource extends Mock implements GroupRemoteDatasource {}

Map<String, dynamic> _groupRow(String id, String name) {
  return {'id': id, 'name': name, 'photo_url': null, 'invite_code': 'ABC12345'};
}

void main() {
  late MockGroupRemoteDatasource datasource;
  late GroupRepositoryImpl repository;

  setUp(() {
    datasource = MockGroupRemoteDatasource();
    repository = GroupRepositoryImpl(datasource);
  });

  test('devolve os grupos em comum mapeados', () async {
    when(
      () => datasource.fetchCommonGroupIds('me', 'other'),
    ).thenAnswer((_) async => ['g1', 'g2']);
    when(() => datasource.fetchGroupsByIds(['g1', 'g2'])).thenAnswer(
      (_) async => [_groupRow('g1', 'Grupo 1'), _groupRow('g2', 'Grupo 2')],
    );

    final groups = await repository.listCommonGroups('me', 'other');

    expect(groups.map((g) => g.id), ['g1', 'g2']);
    expect(groups.map((g) => g.name), ['Grupo 1', 'Grupo 2']);
  });

  test('sem grupos em comum não consulta fetchGroupsByIds', () async {
    when(
      () => datasource.fetchCommonGroupIds('me', 'other'),
    ).thenAnswer((_) async => []);

    final groups = await repository.listCommonGroups('me', 'other');

    expect(groups, isEmpty);
    verifyNever(() => datasource.fetchGroupsByIds(any()));
  });
}
