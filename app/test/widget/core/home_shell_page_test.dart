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
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

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
/// dependências mockadas, não só a inicialmente visível (Feed).
Widget _wrap({
  required MockFeedRepository feedRepository,
  required MockGroupRepository groupRepository,
  required MockGamificationRepository gamificationRepository,
  required MockUserProfileRepository userProfileRepository,
}) {
  when(
    () => feedRepository.listForUser(
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
  late MockGamificationRepository gamificationRepository;
  late MockUserProfileRepository userProfileRepository;

  setUp(() {
    feedRepository = MockFeedRepository();
    groupRepository = MockGroupRepository();
    gamificationRepository = MockGamificationRepository();
    userProfileRepository = MockUserProfileRepository();
  });

  testWidgets('mostra os 5 itens da barra e abre no Feed', (tester) async {
    await tester.pumpWidget(
      _wrap(
        feedRepository: feedRepository,
        groupRepository: groupRepository,
        gamificationRepository: gamificationRepository,
        userProfileRepository: userProfileRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsWidgets); // rótulo da barra + AppBar
    expect(find.text('Grupos'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
    expect(find.text('Rankings'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    // Feed é a aba inicial - AppBar do FeedPage está visível.
    expect(
      find.text('Nenhuma avaliação de quem você segue ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('tocar em Grupos troca de aba', (tester) async {
    await tester.pumpWidget(
      _wrap(
        feedRepository: feedRepository,
        groupRepository: groupRepository,
        gamificationRepository: gamificationRepository,
        userProfileRepository: userProfileRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grupos'));
    await tester.pumpAndSettle();

    expect(
      find.text('Você ainda não participa de nenhum grupo.'),
      findsOneWidget,
    );
  });

  testWidgets('tocar em Criar abre o bottom sheet sem trocar de aba', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        feedRepository: feedRepository,
        groupRepository: groupRepository,
        gamificationRepository: gamificationRepository,
        userProfileRepository: userProfileRepository,
      ),
    );
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
    expect(
      find.text('Nenhuma avaliação de quem você segue ainda.'),
      findsOneWidget,
    );
  });
}
