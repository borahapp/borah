import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/domain/restaurant_search_filters.dart';
import 'package:app/features/search/data/discovery_repository_impl.dart';
import 'package:app/features/search/domain/discovery_repository.dart';
import 'package:app/features/search/presentation/pages/search_page.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRepository extends Mock implements FollowerRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _RestaurantSearchFiltersFake extends Fake
    implements RestaurantSearchFilters {}

UserProfile _person({
  String id = 'user-2',
  String fullName = 'Bruno Costa',
  String? username = 'brunocosta',
  int followersCount = 3,
}) {
  return UserProfile(
    id: id,
    fullName: fullName,
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

Group _group({
  String id = 'group-1',
  String name = 'Os Exploradores',
  int memberCount = 12,
}) {
  return Group(
    id: id,
    name: name,
    description: null,
    photoUrl: null,
    inviteCode: 'ABCDEFGH',
    visibility: 'public',
    memberCount: memberCount,
  );
}

Restaurant _restaurant() {
  return Restaurant(
    id: 'rest-1',
    name: 'Cantina Bella',
    category: 'Italiana',
    totalReviews: 10,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  MockFollowerRepository followerRepository,
  MockGroupRepository groupRepository,
  MockRestaurantRepository restaurantRepository,
  MockDiscoveryRepository discoveryRepository,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SearchPage()),
      GoRoute(
        path: '/users/:id',
        builder: (_, _) => const Scaffold(body: Text('Profile Page')),
      ),
      GoRoute(
        path: '/restaurants/:id',
        builder: (_, _) => const Scaffold(body: Text('Restaurant Page')),
      ),
      GoRoute(
        path: '/groups/:id/preview',
        builder: (_, _) => const Scaffold(body: Text('Group Preview Page')),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, _) => const Scaffold(body: Text('Group Detail Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      followerRepositoryProvider.overrideWithValue(followerRepository),
      groupRepositoryProvider.overrideWithValue(groupRepository),
      restaurantRepositoryProvider.overrideWithValue(restaurantRepository),
      discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
      currentUserIdProvider.overrideWithValue('me'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _submit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextFormField), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  late MockFollowerRepository followerRepository;
  late MockGroupRepository groupRepository;
  late MockRestaurantRepository restaurantRepository;
  late MockDiscoveryRepository discoveryRepository;

  setUpAll(() {
    registerFallbackValue(_RestaurantSearchFiltersFake());
  });

  setUp(() {
    followerRepository = MockFollowerRepository();
    groupRepository = MockGroupRepository();
    restaurantRepository = MockRestaurantRepository();
    discoveryRepository = MockDiscoveryRepository();

    // Padrão: sem sugestões, sem grupos em destaque, sem status de
    // follow/membro conhecido - os testes que precisam de outro
    // comportamento sobrescrevem no corpo do teste (que roda depois do
    // setUp, então a sobrescrita vale).
    when(
      () => discoveryRepository.suggestPeople('me', limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async => const DiscoverySuggestions(people: [], hasMore: false),
    );
    when(
      () => followerRepository.listFollowingAmong('me', any()),
    ).thenAnswer((_) async => {});
    when(
      () => groupRepository.listFeatured(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 10, hasNextPage: false),
    );
    when(
      () => groupRepository.listMyGroupIds('me'),
    ).thenAnswer((_) async => {});
  });

  testWidgets(
    'estado inicial mostra "Você pode conhecer" e "Grupos em destaque"',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          followerRepository,
          groupRepository,
          restaurantRepository,
          discoveryRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Busque por pessoas, grupos ou restaurantes.'),
        findsOneWidget,
      );
      expect(find.text('Você pode conhecer'), findsOneWidget);
      expect(
        find.text('Nenhuma sugestão disponível no momento.'),
        findsOneWidget,
      );
      expect(find.text('Grupos em destaque'), findsOneWidget);
      expect(
        find.text('Nenhum grupo público em destaque no momento.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('"Você pode conhecer" mostra pessoas sugeridas', (tester) async {
    when(
      () => discoveryRepository.suggestPeople('me', limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async => DiscoverySuggestions(
        people: [_person(id: 'sugestao-1', fullName: 'Carla Souza')],
        hasMore: false,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        followerRepository,
        groupRepository,
        restaurantRepository,
        discoveryRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carla Souza'), findsOneWidget);
    expect(find.text('Seguir'), findsOneWidget);
  });

  testWidgets('"Grupos em destaque" mostra grupos públicos', (tester) async {
    when(
      () => groupRepository.listFeatured(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_group()],
        page: 1,
        limit: 10,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        followerRepository,
        groupRepository,
        restaurantRepository,
        discoveryRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Os Exploradores'), findsOneWidget);
    expect(find.text('12 membros'), findsOneWidget);
  });

  testWidgets(
    'grupo em destaque do qual o usuário já participa mostra "Você participa"',
    (tester) async {
      when(
        () => groupRepository.listFeatured(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_group()],
          page: 1,
          limit: 10,
          hasNextPage: false,
        ),
      );
      when(
        () => groupRepository.listMyGroupIds('me'),
      ).thenAnswer((_) async => {'group-1'});

      await tester.pumpWidget(
        _wrap(
          followerRepository,
          groupRepository,
          restaurantRepository,
          discoveryRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Você participa'), findsOneWidget);

      await tester.tap(find.text('Os Exploradores'));
      await tester.pumpAndSettle();

      expect(find.text('Group Detail Page'), findsOneWidget);
    },
  );

  testWidgets(
    'tocar num grupo em destaque do qual não participa abre o perfil público',
    (tester) async {
      when(
        () => groupRepository.listFeatured(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_group()],
          page: 1,
          limit: 10,
          hasNextPage: false,
        ),
      );

      await tester.pumpWidget(
        _wrap(
          followerRepository,
          groupRepository,
          restaurantRepository,
          discoveryRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Os Exploradores'));
      await tester.pumpAndSettle();

      expect(find.text('Group Preview Page'), findsOneWidget);
    },
  );

  testWidgets(
    'busca com resultado mostra pessoas (com username/contador/Seguir), grupos e restaurantes',
    (tester) async {
      when(
        () => followerRepository.searchProfiles('bruno', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_person()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(
        () => groupRepository.search('bruno', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_group()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(
        () => restaurantRepository.search(
          any(
            that: isA<RestaurantSearchFilters>().having(
              (f) => f.query,
              'query',
              'bruno',
            ),
          ),
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_restaurant()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await tester.pumpWidget(
        _wrap(
          followerRepository,
          groupRepository,
          restaurantRepository,
          discoveryRepository,
        ),
      );
      await tester.pumpAndSettle();

      await _submit(tester, 'bruno');

      expect(find.text('Bruno Costa'), findsOneWidget);
      expect(find.text('@brunocosta'), findsOneWidget);
      expect(find.text('3 seguidores'), findsOneWidget);
      expect(find.text('Seguir'), findsOneWidget);
      expect(find.text('Os Exploradores'), findsOneWidget);
      expect(find.text('12 membros'), findsOneWidget);
      expect(find.text('Cantina Bella'), findsOneWidget);
    },
  );

  testWidgets('tocar em uma pessoa navega para o perfil público', (
    tester,
  ) async {
    when(
      () => followerRepository.searchProfiles('bruno', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_person()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(() => groupRepository.search('bruno', page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    when(
      () => restaurantRepository.search(
        any(
          that: isA<RestaurantSearchFilters>().having(
            (f) => f.query,
            'query',
            'bruno',
          ),
        ),
      ),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(
      _wrap(
        followerRepository,
        groupRepository,
        restaurantRepository,
        discoveryRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _submit(tester, 'bruno');
    await tester.tap(find.text('Bruno Costa'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Page'), findsOneWidget);
  });

  testWidgets('tocar em um restaurante navega até a página do restaurante', (
    tester,
  ) async {
    when(
      () => followerRepository.searchProfiles('bella', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    when(() => groupRepository.search('bella', page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    when(
      () => restaurantRepository.search(
        any(
          that: isA<RestaurantSearchFilters>().having(
            (f) => f.query,
            'query',
            'bella',
          ),
        ),
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        followerRepository,
        groupRepository,
        restaurantRepository,
        discoveryRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _submit(tester, 'bella');
    await tester.tap(find.text('Cantina Bella'));
    await tester.pumpAndSettle();

    expect(find.text('Restaurant Page'), findsOneWidget);
  });

  testWidgets('erro na busca mostra estado de erro com retry', (tester) async {
    when(
      () => followerRepository.searchProfiles(any(), page: 1, limit: 20),
    ).thenThrow(Exception('falhou'));
    when(() => groupRepository.search(any(), page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    when(() => restaurantRepository.search(any())).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(
      _wrap(
        followerRepository,
        groupRepository,
        restaurantRepository,
        discoveryRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _submit(tester, 'bruno');

    expect(
      find.text('Não foi possível buscar. Tente novamente.'),
      findsOneWidget,
    );
  });
}
