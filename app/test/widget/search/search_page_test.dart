import 'package:app/core/models/paged_result.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/domain/restaurant_search_filters.dart';
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

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class _RestaurantSearchFiltersFake extends Fake
    implements RestaurantSearchFilters {}

UserProfile _person() {
  return UserProfile(
    id: 'user-2',
    fullName: 'Bruno Costa',
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
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
  MockRestaurantRepository restaurantRepository,
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
    ],
  );

  return ProviderScope(
    overrides: [
      followerRepositoryProvider.overrideWithValue(followerRepository),
      restaurantRepositoryProvider.overrideWithValue(restaurantRepository),
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
  late MockRestaurantRepository restaurantRepository;

  setUpAll(() {
    registerFallbackValue(_RestaurantSearchFiltersFake());
  });

  setUp(() {
    followerRepository = MockFollowerRepository();
    restaurantRepository = MockRestaurantRepository();
  });

  testWidgets('estado inicial mostra mensagem de busca', (tester) async {
    await tester.pumpWidget(_wrap(followerRepository, restaurantRepository));
    await tester.pumpAndSettle();

    expect(find.text('Busque por pessoas ou restaurantes.'), findsOneWidget);
  });

  testWidgets('busca com resultado mostra pessoas, grupos e restaurantes', (
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

    await tester.pumpWidget(_wrap(followerRepository, restaurantRepository));
    await tester.pumpAndSettle();

    await _submit(tester, 'bruno');

    expect(find.text('Bruno Costa'), findsOneWidget);
    expect(find.text('Cantina Bella'), findsOneWidget);
    expect(
      find.text('Busca de grupos públicos chega em breve.'),
      findsOneWidget,
    );
  });

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

    await tester.pumpWidget(_wrap(followerRepository, restaurantRepository));
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

    await tester.pumpWidget(_wrap(followerRepository, restaurantRepository));
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
    when(() => restaurantRepository.search(any())).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(followerRepository, restaurantRepository));
    await tester.pumpAndSettle();

    await _submit(tester, 'bruno');

    expect(
      find.text('Não foi possível buscar. Tente novamente.'),
      findsOneWidget,
    );
  });
}
