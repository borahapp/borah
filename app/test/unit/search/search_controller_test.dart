import 'package:app/core/models/paged_result.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/domain/restaurant_search_filters.dart';
import 'package:app/features/search/application/search_controller.dart';
import 'package:app/features/search/presentation/states/search_status.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRepository extends Mock implements FollowerRepository {}

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class _RestaurantSearchFiltersFake extends Fake
    implements RestaurantSearchFilters {}

UserProfile _person() {
  return UserProfile(
    id: 'user-2',
    fullName: 'Bruno Costa',
    username: 'brunocosta',
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

void main() {
  late MockFollowerRepository followerRepository;
  late MockRestaurantRepository restaurantRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(_RestaurantSearchFiltersFake());
  });

  setUp(() {
    followerRepository = MockFollowerRepository();
    restaurantRepository = MockRestaurantRepository();
    container = ProviderContainer(
      overrides: [
        followerRepositoryProvider.overrideWithValue(followerRepository),
        restaurantRepositoryProvider.overrideWithValue(restaurantRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é SearchInitial', () {
    expect(container.read(searchControllerProvider), isA<SearchInitial>());
  });

  test('busca com sucesso carrega pessoas e restaurantes', () async {
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

    await container.read(searchControllerProvider.notifier).search('bruno');

    final status = container.read(searchControllerProvider);
    expect(status, isA<SearchLoaded>());
    final loaded = status as SearchLoaded;
    expect(loaded.people.items, hasLength(1));
    expect(loaded.restaurants.items, hasLength(1));
  });

  test('query vazia volta para SearchInitial', () async {
    when(
      () => followerRepository.searchProfiles(any(), page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    when(() => restaurantRepository.search(any())).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(searchControllerProvider.notifier).search('algo');
    expect(container.read(searchControllerProvider), isA<SearchLoaded>());

    await container.read(searchControllerProvider.notifier).search('   ');
    expect(container.read(searchControllerProvider), isA<SearchInitial>());
  });

  test('erro em qualquer busca resulta em SearchError', () async {
    when(
      () => followerRepository.searchProfiles(any(), page: 1, limit: 20),
    ).thenThrow(Exception('falhou'));
    when(() => restaurantRepository.search(any())).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(searchControllerProvider.notifier).search('bruno');

    expect(container.read(searchControllerProvider), isA<SearchError>());
  });

  test(
    'resultado de busca desatualizada é descartado (concorrência)',
    () async {
      when(
        () => followerRepository.searchProfiles('lento', page: 1, limit: 20),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return PagedResult(
          items: [_person()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        );
      });
      when(
        () => restaurantRepository.search(
          any(
            that: isA<RestaurantSearchFilters>().having(
              (f) => f.query,
              'query',
              'lento',
            ),
          ),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const PagedResult<Restaurant>(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        );
      });
      when(
        () => followerRepository.searchProfiles('rapido', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [],
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
              'rapido',
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

      final notifier = container.read(searchControllerProvider.notifier);
      final slow = notifier.search('lento');
      await notifier.search('rapido');
      await slow;

      final status = container.read(searchControllerProvider);
      expect(status, isA<SearchLoaded>());
      final loaded = status as SearchLoaded;
      expect(loaded.restaurants.items, hasLength(1));
      expect(loaded.restaurants.items.single.id, 'rest-1');
    },
  );
}
