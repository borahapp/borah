import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/data/user_remote_datasource.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockUserRemoteDatasource extends Mock implements UserRemoteDatasource {}

Map<String, dynamic> _row({String? username}) {
  return {
    'id': 'user-1',
    'full_name': 'Ana',
    'username': username,
    'bio': null,
    'avatar_url': null,
    'city': null,
    'state': null,
    'followers_count': 5,
    'following_count': 2,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-01T00:00:00.000Z',
  };
}

void main() {
  late MockUserRemoteDatasource datasource;
  late UserProfileRepositoryImpl repository;

  setUp(() {
    datasource = MockUserRemoteDatasource();
    repository = UserProfileRepositoryImpl(datasource);
    registerFallbackValue(<String, dynamic>{});
  });

  test(
    'updateProfile com username válido mapeia followers/following/username',
    () async {
      when(
        () => datasource.updateProfile('user-1', any()),
      ).thenAnswer((_) async => _row(username: 'anasilva'));

      final profile = await repository.updateProfile(
        'user-1',
        username: 'anasilva',
      );

      expect(profile.username, 'anasilva');
      expect(profile.followersCount, 5);
      expect(profile.followingCount, 2);
    },
  );

  test('username duplicado (Postgres 23505) vira mensagem amigável', () async {
    when(() => datasource.updateProfile('user-1', any())).thenThrow(
      const PostgrestException(
        message:
            'duplicate key value violates unique constraint '
            '"profiles_username_unique_idx"',
        code: '23505',
      ),
    );

    expect(
      () => repository.updateProfile('user-1', username: 'jasilva'),
      throwsA(
        isA<UserProfileRepositoryException>().having(
          (e) => e.message,
          'message',
          'Nome de usuário já está em uso.',
        ),
      ),
    );
  });

  test('outro erro do Postgrest preserva a mensagem original', () async {
    when(
      () => datasource.updateProfile('user-1', any()),
    ).thenThrow(const PostgrestException(message: 'falha genérica'));

    expect(
      () => repository.updateProfile('user-1', fullName: 'Ana'),
      throwsA(
        isA<UserProfileRepositoryException>().having(
          (e) => e.message,
          'message',
          'falha genérica',
        ),
      ),
    );
  });
}
