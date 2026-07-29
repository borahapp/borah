import 'package:app/core/models/paged_result.dart';
import 'package:app/features/administration/application/admin_users_controller.dart';
import 'package:app/features/administration/presentation/states/admin_users_status.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

UserProfile _profile({String id = 'user-1'}) {
  return UserProfile(
    id: id,
    fullName: 'Ana',
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockUserProfileRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockUserProfileRepository();
    container = ProviderContainer(
      overrides: [userProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é AdminUsersInitial', () {
    expect(
      container.read(adminUsersControllerProvider),
      isA<AdminUsersInitial>(),
    );
  });

  test('load com resultados -> AdminUsersLoaded', () async {
    when(() => repository.listAll(query: null, page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(adminUsersControllerProvider.notifier).load();

    expect(
      container.read(adminUsersControllerProvider),
      isA<AdminUsersLoaded>(),
    );
  });

  test('load sem resultados -> AdminUsersEmpty', () async {
    when(() => repository.listAll(query: null, page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(adminUsersControllerProvider.notifier).load();

    expect(
      container.read(adminUsersControllerProvider),
      isA<AdminUsersEmpty>(),
    );
  });

  test('load com falha -> AdminUsersError', () async {
    when(
      () => repository.listAll(query: null, page: 1, limit: 20),
    ).thenThrow(const UserProfileRepositoryException('Falha.'));

    await container.read(adminUsersControllerProvider.notifier).load();

    expect(
      container.read(adminUsersControllerProvider),
      isA<AdminUsersError>(),
    );
  });
}
