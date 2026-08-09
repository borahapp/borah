import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/social/presentation/pages/public_profile_page.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockFollowerRepository extends Mock implements FollowerRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

UserProfile _profile({String id = 'other-1', String? username = 'brunocosta'}) {
  return UserProfile(
    id: id,
    fullName: 'Bruno Costa',
    username: username,
    bio: 'Adoro um bom rolê.',
    avatarUrl: null,
    city: null,
    state: null,
    followersCount: 48,
    followingCount: 72,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

UserProgress _progress() {
  return UserProgress(
    userId: 'other-1',
    xp: 1840,
    points: 1840,
    level: 12,
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap({
  required MockUserProfileRepository userProfileRepository,
  required MockFollowerRepository followerRepository,
  required MockReviewRepository reviewRepository,
  required MockGamificationRepository gamificationRepository,
  required MockGroupRepository groupRepository,
  String? currentUserId = 'me',
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const PublicProfilePage(userId: 'other-1'),
      ),
      GoRoute(
        path: '/users/:id/followers',
        builder: (_, _) => const Scaffold(body: Text('Followers Page')),
      ),
      GoRoute(
        path: '/users/:id/following',
        builder: (_, _) => const Scaffold(body: Text('Following Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
      followerRepositoryProvider.overrideWithValue(followerRepository),
      reviewRepositoryProvider.overrideWithValue(reviewRepository),
      gamificationRepositoryProvider.overrideWithValue(gamificationRepository),
      groupRepositoryProvider.overrideWithValue(groupRepository),
      currentUserIdProvider.overrideWithValue(currentUserId),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockUserProfileRepository userProfileRepository;
  late MockFollowerRepository followerRepository;
  late MockReviewRepository reviewRepository;
  late MockGamificationRepository gamificationRepository;
  late MockGroupRepository groupRepository;

  setUp(() {
    userProfileRepository = MockUserProfileRepository();
    followerRepository = MockFollowerRepository();
    reviewRepository = MockReviewRepository();
    gamificationRepository = MockGamificationRepository();
    groupRepository = MockGroupRepository();

    when(
      () => userProfileRepository.getProfile('other-1'),
    ).thenAnswer((_) async => _profile());
    when(
      () => followerRepository.isFollowing(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => reviewRepository.listByUser('other-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => const PagedResult<Review>(
        items: [],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => gamificationRepository.getProgress('other-1'),
    ).thenAnswer((_) async => _progress());
    when(
      () => gamificationRepository.listAllBadges(),
    ).thenAnswer((_) async => const []);
    when(
      () => gamificationRepository.listEarnedBadges('other-1'),
    ).thenAnswer((_) async => const []);
    when(
      () => groupRepository.listCommonGroups(any(), 'other-1'),
    ).thenAnswer((_) async => []);
  });

  testWidgets(
    'mostra username, contadores, nível/XP e botão Seguir para outro usuário',
    (tester) async {
      when(
        () => followerRepository.isFollowing('me', 'other-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        _wrap(
          userProfileRepository: userProfileRepository,
          followerRepository: followerRepository,
          reviewRepository: reviewRepository,
          gamificationRepository: gamificationRepository,
          groupRepository: groupRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('@brunocosta'), findsOneWidget);
      expect(find.text('48 seguidores'), findsOneWidget);
      expect(find.text('72 seguindo'), findsOneWidget);
      expect(find.text('Seguir'), findsOneWidget);
      expect(find.text('Nível 12'), findsOneWidget);
      expect(find.text('1840 XP'), findsOneWidget);
    },
  );

  testWidgets('sem username não mostra "@null"', (tester) async {
    when(
      () => userProfileRepository.getProfile('other-1'),
    ).thenAnswer((_) async => _profile(username: null));
    when(
      () => followerRepository.isFollowing('me', 'other-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _wrap(
        userProfileRepository: userProfileRepository,
        followerRepository: followerRepository,
        reviewRepository: reviewRepository,
        gamificationRepository: gamificationRepository,
        groupRepository: groupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('@null'), findsNothing);
  });

  testWidgets(
    'no próprio perfil não mostra o botão Seguir (defesa de self-follow na UI)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          userProfileRepository: userProfileRepository,
          followerRepository: followerRepository,
          reviewRepository: reviewRepository,
          gamificationRepository: gamificationRepository,
          groupRepository: groupRepository,
          currentUserId: 'other-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Seguir'), findsNothing);
      expect(find.text('Seguindo'), findsNothing);
    },
  );

  testWidgets('tocar em seguidores navega para a lista de seguidores', (
    tester,
  ) async {
    when(
      () => followerRepository.isFollowing('me', 'other-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _wrap(
        userProfileRepository: userProfileRepository,
        followerRepository: followerRepository,
        reviewRepository: reviewRepository,
        gamificationRepository: gamificationRepository,
        groupRepository: groupRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('48 seguidores'));
    await tester.pumpAndSettle();

    expect(find.text('Followers Page'), findsOneWidget);
  });

  testWidgets('grupos em comum aparecem quando existem', (tester) async {
    when(
      () => followerRepository.isFollowing('me', 'other-1'),
    ).thenAnswer((_) async => false);
    when(() => groupRepository.listCommonGroups('me', 'other-1')).thenAnswer(
      (_) async => const [
        Group(
          id: 'g1',
          name: 'Os Exploradores',
          description: null,
          photoUrl: null,
          inviteCode: 'ABC12345',
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        userProfileRepository: userProfileRepository,
        followerRepository: followerRepository,
        reviewRepository: reviewRepository,
        gamificationRepository: gamificationRepository,
        groupRepository: groupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grupos em comum'), findsOneWidget);
    expect(find.text('Os Exploradores'), findsOneWidget);
  });
}
