import 'package:app/features/social/data/follower_remote_datasource.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRemoteDatasource extends Mock
    implements FollowerRemoteDatasource {}

void main() {
  late MockFollowerRemoteDatasource datasource;
  late FollowerRepositoryImpl repository;

  setUp(() {
    datasource = MockFollowerRemoteDatasource();
    repository = FollowerRepositoryImpl(datasource);
  });

  group('listFollowingAmong', () {
    test('devolve como Set (sem duplicados) os ids já seguidos', () async {
      when(
        () => datasource.listFollowingAmong('user-1', ['a', 'b', 'c']),
      ).thenAnswer((_) async => ['a', 'b']);

      final result = await repository.listFollowingAmong('user-1', [
        'a',
        'b',
        'c',
      ]);

      expect(result, {'a', 'b'});
    });

    test('lista vazia de candidatos não chama o datasource com erro', () async {
      when(
        () => datasource.listFollowingAmong('user-1', []),
      ).thenAnswer((_) async => []);

      final result = await repository.listFollowingAmong('user-1', []);

      expect(result, isEmpty);
    });
  });
}
