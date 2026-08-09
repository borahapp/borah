import 'package:app/features/search/data/discovery_remote_datasource.dart';
import 'package:app/features/search/data/discovery_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRemoteDatasource extends Mock
    implements DiscoveryRemoteDatasource {}

Map<String, dynamic> _row(String id) {
  return {
    'id': id,
    'full_name': 'Pessoa $id',
    'username': null,
    'bio': null,
    'avatar_url': null,
    'city': null,
    'state': null,
    'followers_count': 0,
    'following_count': 0,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-01T00:00:00.000Z',
  };
}

void main() {
  late MockDiscoveryRemoteDatasource datasource;
  late DiscoveryRepositoryImpl repository;

  setUp(() {
    datasource = MockDiscoveryRemoteDatasource();
    repository = DiscoveryRepositoryImpl(datasource);

    // Padrão: sem grupos/seguidos - cada teste sobrescreve o que precisa.
    when(
      () => datasource.fetchMyGroupIds('user-1'),
    ).thenAnswer((_) async => []);
    when(
      () => datasource.fetchGroupMemberIds(
        any(),
        excludeUserId: any(named: 'excludeUserId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () =>
          datasource.fetchFollowingSeeds('user-1', limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => datasource.fetchFollowerIdsOf(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => datasource.fetchFollowingAmong('user-1', any()),
    ).thenAnswer((_) async => {});
  });

  test('sem grupos e sem seguidores -> lista vazia', () async {
    final result = await repository.suggestPeople('user-1', limit: 8);

    expect(result.people, isEmpty);
    expect(result.hasMore, isFalse);
  });

  test(
    'prioridade 1 (mesmo grupo) preenche o limite sem consultar prioridade 2',
    () async {
      when(
        () => datasource.fetchMyGroupIds('user-1'),
      ).thenAnswer((_) async => ['g1']);
      when(
        () => datasource.fetchGroupMemberIds(['g1'], excludeUserId: 'user-1'),
      ).thenAnswer((_) async => ['a', 'b']);
      when(
        () => datasource.fetchFollowingAmong('user-1', ['a', 'b']),
      ).thenAnswer((_) async => {});
      when(
        () => datasource.fetchProfilesByIds(['a', 'b']),
      ).thenAnswer((_) async => [_row('a'), _row('b')]);

      final result = await repository.suggestPeople('user-1', limit: 2);

      expect(result.people.map((p) => p.id), ['a', 'b']);
      expect(result.hasMore, isFalse);
      verifyNever(
        () => datasource.fetchFollowingSeeds(
          'user-1',
          limit: any(named: 'limit'),
        ),
      );
    },
  );

  test(
    'prioridade 2 (amigos de amigos) só é buscada quando a 1 não preenche o limite',
    () async {
      when(
        () => datasource.fetchMyGroupIds('user-1'),
      ).thenAnswer((_) async => ['g1']);
      when(
        () => datasource.fetchGroupMemberIds(['g1'], excludeUserId: 'user-1'),
      ).thenAnswer((_) async => ['a']);
      when(
        () => datasource.fetchFollowingSeeds(
          'user-1',
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => ['seed-1']);
      when(
        () => datasource.fetchFollowerIdsOf([
          'seed-1',
        ], limit: any(named: 'limit')),
      ).thenAnswer((_) async => ['b']);
      when(
        () => datasource.fetchFollowingAmong('user-1', ['a', 'b']),
      ).thenAnswer((_) async => {});
      when(
        () => datasource.fetchProfilesByIds(['a', 'b']),
      ).thenAnswer((_) async => [_row('a'), _row('b')]);

      final result = await repository.suggestPeople('user-1', limit: 8);

      // Prioridade 1 primeiro, depois prioridade 2 - ordem preservada.
      expect(result.people.map((p) => p.id), ['a', 'b']);
    },
  );

  test('remove o próprio usuário e duplicados entre as 2 fontes', () async {
    when(
      () => datasource.fetchMyGroupIds('user-1'),
    ).thenAnswer((_) async => ['g1']);
    when(
      () => datasource.fetchGroupMemberIds(['g1'], excludeUserId: 'user-1'),
    ).thenAnswer((_) async => ['a', 'user-1']);
    when(
      () =>
          datasource.fetchFollowingSeeds('user-1', limit: any(named: 'limit')),
    ).thenAnswer((_) async => ['seed-1']);
    when(
      () =>
          datasource.fetchFollowerIdsOf(['seed-1'], limit: any(named: 'limit')),
    ).thenAnswer((_) async => ['a']); // duplicado com a prioridade 1
    when(
      () => datasource.fetchFollowingAmong('user-1', ['a']),
    ).thenAnswer((_) async => {});
    when(
      () => datasource.fetchProfilesByIds(['a']),
    ).thenAnswer((_) async => [_row('a')]);

    final result = await repository.suggestPeople('user-1', limit: 8);

    expect(result.people.map((p) => p.id), ['a']);
  });

  test('remove candidatos que o usuário já segue', () async {
    when(
      () => datasource.fetchMyGroupIds('user-1'),
    ).thenAnswer((_) async => ['g1']);
    when(
      () => datasource.fetchGroupMemberIds(['g1'], excludeUserId: 'user-1'),
    ).thenAnswer((_) async => ['a', 'b']);
    when(
      () => datasource.fetchFollowingAmong('user-1', ['a', 'b']),
    ).thenAnswer((_) async => {'a'});
    when(
      () => datasource.fetchProfilesByIds(['b']),
    ).thenAnswer((_) async => [_row('b')]);

    final result = await repository.suggestPeople('user-1', limit: 8);

    expect(result.people.map((p) => p.id), ['b']);
  });

  test('limita ao limit pedido e reporta hasMore', () async {
    when(
      () => datasource.fetchMyGroupIds('user-1'),
    ).thenAnswer((_) async => ['g1']);
    when(
      () => datasource.fetchGroupMemberIds(['g1'], excludeUserId: 'user-1'),
    ).thenAnswer((_) async => ['a', 'b', 'c']);
    when(
      () => datasource.fetchFollowingAmong('user-1', ['a', 'b', 'c']),
    ).thenAnswer((_) async => {});
    when(
      () => datasource.fetchProfilesByIds(['a', 'b']),
    ).thenAnswer((_) async => [_row('a'), _row('b')]);

    final result = await repository.suggestPeople('user-1', limit: 2);

    expect(result.people.map((p) => p.id), ['a', 'b']);
    expect(result.hasMore, isTrue);
  });
}
