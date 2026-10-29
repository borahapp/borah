import 'package:app/core/models/paged_result.dart';
import 'package:app/core/router/home_shell_page.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event_repository.dart';
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
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockEventRepository extends Mock implements EventRepository {}

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
/// dependências mockadas, não só a inicialmente visível (Home, FASE 01).
/// `FeedRepository` não é mais necessário aqui - desde a FASE 01 o Feed
/// não tem mais porta de entrada em `HomeShellPage` (continua existindo
/// em `features/social/`, só não aparece nesta árvore de widgets).
Widget _wrap({
  required MockGroupRepository groupRepository,
  required MockEventRepository eventRepository,
  required MockFollowerRepository followerRepository,
  required MockDiscoveryRepository discoveryRepository,
  required MockGamificationRepository gamificationRepository,
  required MockUserProfileRepository userProfileRepository,
}) {
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
      groupRepositoryProvider.overrideWithValue(groupRepository),
      eventRepositoryProvider.overrideWithValue(eventRepository),
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
  late MockGroupRepository groupRepository;
  late MockEventRepository eventRepository;
  late MockFollowerRepository followerRepository;
  late MockDiscoveryRepository discoveryRepository;
  late MockGamificationRepository gamificationRepository;
  late MockUserProfileRepository userProfileRepository;

  setUp(() {
    groupRepository = MockGroupRepository();
    eventRepository = MockEventRepository();
    followerRepository = MockFollowerRepository();
    discoveryRepository = MockDiscoveryRepository();
    gamificationRepository = MockGamificationRepository();
    userProfileRepository = MockUserProfileRepository();
  });

  Widget wrap() => _wrap(
    groupRepository: groupRepository,
    eventRepository: eventRepository,
    followerRepository: followerRepository,
    discoveryRepository: discoveryRepository,
    gamificationRepository: gamificationRepository,
    userProfileRepository: userProfileRepository,
  );

  testWidgets('mostra os 5 itens da barra e abre na nova Home', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Início'), findsWidgets); // rótulo da barra
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
    expect(find.text('Pontuação'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    // Início é a aba inicial (FASE 01) - título + CTA principal da nova
    // Home, sem grupos/rolês mockados (estado vazio).
    expect(find.text('BORAH'), findsOneWidget);
    expect(find.text('Criar novo rolê'), findsOneWidget);
    expect(
      find.text('Você ainda não tem nenhum rolê marcado.'),
      findsOneWidget,
    );
  });

  testWidgets('HOME-09: Feed não aparece em nenhum lugar da navegação', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsNothing);
    expect(find.text('Para Você'), findsNothing);
    expect(find.text('Seguindo'), findsNothing);
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

    // `find.widgetWithText(ListTile, ...)`, não `find.text(...)`: a Home
    // por trás do sheet também mostra "Criar grupo" (ação do estado
    // vazio de "Meus grupos", sem nenhum grupo mockado) - os itens do
    // sheet são `ListTile`, o botão da Home não é.
    expect(find.widgetWithText(ListTile, 'Criar grupo'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Criar rolê'), findsOneWidget);
    expect(
      find.widgetWithText(ListTile, 'Avaliar restaurante'),
      findsOneWidget,
    );

    // Fecha o sheet e confirma que a aba selecionada continua Início (a
    // seleção da barra nunca mudou para "Criar", só o sheet abriu).
    await tester.tapAt(const Offset(200, 50));
    await tester.pumpAndSettle();
    expect(find.text('Criar novo rolê'), findsOneWidget);
  });
}
