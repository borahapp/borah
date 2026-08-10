import 'package:app/core/models/paged_result.dart';
import 'package:app/core/router/home_shell_page.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_badge.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/groups_activity_summary.dart';
import 'package:app/features/gamification/domain/ranking_entry.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/search/data/discovery_repository_impl.dart';
import 'package:app/features/search/domain/discovery_repository.dart';
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockFollowerRepository extends Mock implements FollowerRepository {}

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

UserProfile _profile() {
  return UserProfile(
    id: 'user-1',
    fullName: 'Ana Silva',
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

UserProgress _progress() {
  return UserProgress(
    userId: 'user-1',
    xp: 100,
    points: 100,
    level: 2,
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// `HomeShellPage` renderiza as 4 páginas simultaneamente via
/// `IndexedStack` (preserva estado) - todas precisam de suas
/// dependências mockadas, não só a inicialmente visível (Feed). O Feed
/// (FASE SOCIAL 4) tem 2 abas ("Para Você"/"Seguindo") construídas juntas
/// pelo `TabBarView`, então as duas chamam `loadForUser` no mesmo pump.
Widget _wrap({
  required MockFeedRepository feedRepository,
  required MockGroupRepository groupRepository,
  required MockFollowerRepository followerRepository,
  required MockDiscoveryRepository discoveryRepository,
  required MockGamificationRepository gamificationRepository,
  required MockUserProfileRepository userProfileRepository,
}) {
  when(
    () => feedRepository.listForYou(
      'user-1',
      page: 1,
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async =>
        const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
  );
  when(
    () => feedRepository.listFollowing(
      'user-1',
      page: 1,
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async =>
        const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
  );
  when(() => groupRepository.listMine()).thenAnswer((_) async => []);
  when(
    () => groupRepository.listMyGroupIds('user-1'),
  ).thenAnswer((_) async => {});
  when(
    () => groupRepository.listFeatured(page: 1, limit: any(named: 'limit')),
  ).thenAnswer(
    (_) async =>
        const PagedResult(items: [], page: 1, limit: 10, hasNextPage: false),
  );
  when(
    () =>
        discoveryRepository.suggestPeople('user-1', limit: any(named: 'limit')),
  ).thenAnswer(
    (_) async => const DiscoverySuggestions(people: [], hasMore: false),
  );
  when(
    () => gamificationRepository.getProgress('user-1'),
  ).thenAnswer((_) async => _progress());
  when(
    () => gamificationRepository.listAllBadges(),
  ).thenAnswer((_) async => <GamificationBadge>[]);
  when(
    () => gamificationRepository.listEarnedBadges('user-1'),
  ).thenAnswer((_) async => []);
  when(
    () => gamificationRepository.getGroupsActivitySummary('user-1'),
  ).thenAnswer(
    (_) async => const GroupsActivitySummary(eventsCount: 0, reviewsCount: 0),
  );
  when(
    () => gamificationRepository.listGlobalRanking(
      page: 1,
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => const PagedResult<RankingEntry>(
      items: [],
      page: 1,
      limit: 20,
      hasNextPage: false,
    ),
  );
  when(
    () => userProfileRepository.getProfile('user-1'),
  ).thenAnswer((_) async => _profile());

  return ProviderScope(
    overrides: [
      feedRepositoryProvider.overrideWithValue(feedRepository),
      groupRepositoryProvider.overrideWithValue(groupRepository),
      followerRepositoryProvider.overrideWithValue(followerRepository),
      discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
      gamificationRepositoryProvider.overrideWithValue(gamificationRepository),
      userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: const MaterialApp(home: HomeShellPage()),
  );
}

void main() {
  late MockFeedRepository feedRepository;
  late MockGroupRepository groupRepository;
  late MockFollowerRepository followerRepository;
  late MockDiscoveryRepository discoveryRepository;
  late MockGamificationRepository gamificationRepository;
  late MockUserProfileRepository userProfileRepository;

  setUp(() {
    feedRepository = MockFeedRepository();
    groupRepository = MockGroupRepository();
    followerRepository = MockFollowerRepository();
    discoveryRepository = MockDiscoveryRepository();
    gamificationRepository = MockGamificationRepository();
    userProfileRepository = MockUserProfileRepository();
  });

  Widget wrap() => _wrap(
    feedRepository: feedRepository,
    groupRepository: groupRepository,
    followerRepository: followerRepository,
    discoveryRepository: discoveryRepository,
    gamificationRepository: gamificationRepository,
    userProfileRepository: userProfileRepository,
  );

  testWidgets('mostra os 5 itens da barra e abre no Feed', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsWidgets); // rótulo da barra + AppBar
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
    expect(find.text('Rankings'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    // Feed é a aba inicial - as 2 abas do Feed (Para Você/Seguindo) estão
    // visíveis, ambas vazias (sem seguidos/grupos/badges mockados).
    expect(find.text('Para Você'), findsOneWidget);
    expect(find.text('Seguindo'), findsOneWidget);
    expect(
      find.text('Comece a seguir pessoas e grupos para personalizar seu Feed.'),
      findsOneWidget,
    );
  });

  testWidgets('tocar em Explorar troca de aba para a Pesquisa', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();

    expect(find.text('Pesquisar'), findsWidgets); // AppBar + campo de busca
    expect(find.text('Você pode conhecer'), findsOneWidget);
  });

  testWidgets('tocar em Criar abre o bottom sheet sem trocar de aba', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Criar grupo'), findsOneWidget);
    expect(find.text('Criar rolê'), findsOneWidget);
    expect(find.text('Avaliar restaurante'), findsOneWidget);

    // Fecha o sheet e confirma que a aba selecionada continua Feed (a
    // seleção da barra nunca mudou para "Criar", só o sheet abriu).
    await tester.tapAt(const Offset(200, 50));
    await tester.pumpAndSettle();
    expect(find.text('Para Você'), findsOneWidget);
  });
}
