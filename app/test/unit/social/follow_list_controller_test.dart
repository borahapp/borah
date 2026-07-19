import 'package:app/core/models/paged_result.dart';
import 'package:app/features/social/application/follow_list_controller.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/social/presentation/states/follow_list_status.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRepository extends Mock implements FollowerRepository {}

UserProfile _profile({String id = 'user-2'}) {
  return UserProfile(
    id: id,
    fullName: 'Maria',
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockFollowerRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFollowerRepository();
    container = ProviderContainer(
      overrides: [followerRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FollowListInitial', () {
    expect(
      container.read(followListControllerProvider),
      isA<FollowListInitial>(),
    );
  });

  test('load(followers) com resultados -> FollowListLoaded', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(followListControllerProvider.notifier)
        .load('user-1', FollowListType.followers);

    expect(
      container.read(followListControllerProvider),
      isA<FollowListLoaded>(),
    );
    verify(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).called(1);
  });

  test('load(following) chama listFollowing', () async {
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(followListControllerProvider.notifier)
        .load('user-1', FollowListType.following);

    verify(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).called(1);
  });

  test('sem resultados -> FollowListEmpty', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(followListControllerProvider.notifier)
        .load('user-1', FollowListType.followers);

    expect(
      container.read(followListControllerProvider),
      isA<FollowListEmpty>(),
    );
  });

  test('com falha -> FollowListError', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenThrow(const FollowerRepositoryException('Falha ao carregar.'));

    await container
        .read(followListControllerProvider.notifier)
        .load('user-1', FollowListType.followers);

    expect(
      container.read(followListControllerProvider),
      isA<FollowListError>(),
    );
  });
}
