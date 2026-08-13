import 'package:app/core/models/paged_result.dart';
import 'package:app/features/social/application/feed_controller.dart';
import 'package:app/features/social/application/public_profile_provider.dart';
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/social/presentation/widgets/person_list_tile.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRepository extends Mock implements FollowerRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

UserProfile _person({String id = 'other-1', int followersCount = 3}) {
  return UserProfile(
    id: id,
    fullName: 'Bruno Costa',
    username: 'brunocosta',
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

UserProfile _me() {
  return UserProfile(
    id: 'me',
    fullName: 'Eu',
    username: null,
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    followersCount: 0,
    followingCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap({
  required MockFollowerRepository followerRepository,
  required MockUserProfileRepository userProfileRepository,
  required MockFeedRepository feedRepository,
  bool initialIsFollowing = false,
}) {
  return ProviderScope(
    overrides: [
      followerRepositoryProvider.overrideWithValue(followerRepository),
      userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
      feedRepositoryProvider.overrideWithValue(feedRepository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: PersonListTile(
          person: _person(),
          currentUserId: 'me',
          initialIsFollowing: initialIsFollowing,
        ),
      ),
    ),
  );
}

/// Testes de [PersonListTile] (usado por Busca/"Você pode conhecer"/
/// Seguidores/Seguindo) - 2B.3-G (fix do F2 da auditoria 2B.3-F). Este
/// widget não usa `FollowController` (decisão de arquitetura documentada
/// na própria classe - ver comentário), então precisa do mesmo efeito
/// colateral de atualização testado separadamente em
/// `follow_controller_test.dart`.
void main() {
  late MockFollowerRepository followerRepository;
  late MockUserProfileRepository userProfileRepository;
  late MockFeedRepository feedRepository;

  setUp(() {
    followerRepository = MockFollowerRepository();
    userProfileRepository = MockUserProfileRepository();
    feedRepository = MockFeedRepository();
    when(
      () => userProfileRepository.getProfile('me'),
    ).thenAnswer((_) async => _me());
  });

  testWidgets('tocar em "Seguir" chama o repositório e atualiza o rótulo '
      'para "Seguindo"', (tester) async {
    when(
      () => followerRepository.follow('me', 'other-1'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrap(
        followerRepository: followerRepository,
        userProfileRepository: userProfileRepository,
        feedRepository: feedRepository,
      ),
    );

    expect(find.text('Seguir'), findsOneWidget);

    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();

    verify(() => followerRepository.follow('me', 'other-1')).called(1);
    expect(find.text('Seguindo'), findsOneWidget);
  });

  testWidgets('tocar em "Seguindo" chama unfollow e atualiza o rótulo para '
      '"Seguir"', (tester) async {
    when(
      () => followerRepository.unfollow('me', 'other-1'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrap(
        followerRepository: followerRepository,
        userProfileRepository: userProfileRepository,
        feedRepository: feedRepository,
        initialIsFollowing: true,
      ),
    );

    expect(find.text('Seguindo'), findsOneWidget);

    await tester.tap(find.text('Seguindo'));
    await tester.pumpAndSettle();

    verify(() => followerRepository.unfollow('me', 'other-1')).called(1);
    expect(find.text('Seguir'), findsOneWidget);
  });

  testWidgets(
    'seguir com sucesso recarrega o perfil do usuário atual (contador '
    '"seguindo")',
    (tester) async {
      when(
        () => followerRepository.follow('me', 'other-1'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        _wrap(
          followerRepository: followerRepository,
          userProfileRepository: userProfileRepository,
          feedRepository: feedRepository,
        ),
      );

      await tester.tap(find.text('Seguir'));
      await tester.pumpAndSettle();

      verify(() => userProfileRepository.getProfile('me')).called(1);
    },
  );

  testWidgets(
    'seguir com sucesso invalida o perfil público do seguido (contador '
    '"seguidores") - releitura busca de novo no repositório',
    (tester) async {
      when(
        () => followerRepository.follow('me', 'other-1'),
      ).thenAnswer((_) async {});
      when(
        () => userProfileRepository.getProfile('other-1'),
      ).thenAnswer((_) async => _person());

      final container = ProviderContainer(
        overrides: [
          followerRepositoryProvider.overrideWithValue(followerRepository),
          userProfileRepositoryProvider.overrideWithValue(
            userProfileRepository,
          ),
          feedRepositoryProvider.overrideWithValue(feedRepository),
        ],
      );
      addTearDown(container.dispose);

      // Simula `PublicProfilePage` já ter lido o perfil antes do follow.
      await container.read(publicProfileProvider('other-1').future);
      verify(() => userProfileRepository.getProfile('other-1')).called(1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: PersonListTile(
                person: _person(),
                currentUserId: 'me',
                initialIsFollowing: false,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Seguir'));
      await tester.pumpAndSettle();

      await container.read(publicProfileProvider('other-1').future);
      verify(() => userProfileRepository.getProfile('other-1')).called(1);
    },
  );

  testWidgets('seguir com sucesso atualiza o Feed "Seguindo" já carregado', (
    tester,
  ) async {
    when(
      () => followerRepository.follow('me', 'other-1'),
    ).thenAnswer((_) async {});
    when(
      () => feedRepository.listFollowing('me', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    final container = ProviderContainer(
      overrides: [
        followerRepositoryProvider.overrideWithValue(followerRepository),
        userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
        feedRepositoryProvider.overrideWithValue(feedRepository),
      ],
    );
    addTearDown(container.dispose);

    // Simula a aba "Seguindo" já visitada.
    await container
        .read(feedFollowingControllerProvider.notifier)
        .loadForUser('me');
    verify(
      () => feedRepository.listFollowing('me', page: 1, limit: 20),
    ).called(1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: PersonListTile(
              person: _person(),
              currentUserId: 'me',
              initialIsFollowing: false,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();

    verify(
      () => feedRepository.listFollowing('me', page: 1, limit: 20),
    ).called(1);
  });

  testWidgets('falha ao seguir mostra snackbar e mantém o rótulo "Seguir"', (
    tester,
  ) async {
    when(
      () => followerRepository.follow('me', 'other-1'),
    ).thenThrow(Exception('falhou'));

    await tester.pumpWidget(
      _wrap(
        followerRepository: followerRepository,
        userProfileRepository: userProfileRepository,
        feedRepository: feedRepository,
      ),
    );

    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();

    expect(find.text('Seguir'), findsOneWidget);
    expect(
      find.text('Não foi possível atualizar. Tente novamente.'),
      findsOneWidget,
    );
    verifyNever(() => userProfileRepository.getProfile('me'));
  });
}
