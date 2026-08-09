import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/social/presentation/pages/follow_list_page.dart';
import 'package:app/features/social/presentation/states/follow_list_status.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRepository extends Mock implements FollowerRepository {}

UserProfile _person(String id, {String? username, int followersCount = 0}) {
  return UserProfile(
    id: id,
    fullName: 'Pessoa $id',
    username: username,
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    followersCount: followersCount,
    followingCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(MockFollowerRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const FollowListPage(
          userId: 'other-1',
          type: FollowListType.followers,
        ),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, _) => const Scaffold(body: Text('Profile Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      followerRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('me'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockFollowerRepository repository;

  setUp(() {
    repository = MockFollowerRepository();
  });

  testWidgets('mostra username, contador e botão Seguir/Seguindo por linha', (
    tester,
  ) async {
    when(
      () => repository.listFollowers('other-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [
          _person('a', username: 'pessoa_a', followersCount: 3),
          _person('b', username: null, followersCount: 0),
        ],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.listFollowingAmong('me', ['a', 'b']),
    ).thenAnswer((_) async => {'a'});

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('@pessoa_a'), findsOneWidget);
    expect(find.text('3 seguidores'), findsOneWidget);
    expect(find.text('Seguindo'), findsOneWidget); // linha "a", já seguida
    expect(find.text('Seguir'), findsOneWidget); // linha "b"
  });

  testWidgets('tocar numa linha navega até o perfil da pessoa', (tester) async {
    when(
      () => repository.listFollowers('other-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_person('a', username: 'pessoa_a')],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.listFollowingAmong('me', ['a']),
    ).thenAnswer((_) async => {});

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pessoa a'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Page'), findsOneWidget);
  });

  testWidgets('lista vazia mostra estado vazio', (tester) async {
    when(
      () => repository.listFollowers('other-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum seguidor ainda.'), findsOneWidget);
  });
}
