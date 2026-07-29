import 'package:app/core/models/paged_result.dart';
import 'package:app/features/restaurants/application/restaurants_controller.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/domain/restaurant_search_filters.dart';
import 'package:app/features/restaurants/presentation/states/restaurants_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class FakeRestaurantSearchFilters extends Fake
    implements RestaurantSearchFilters {}

Restaurant _restaurant({String id = 'r-1', String name = 'Bar do Zé'}) {
  return Restaurant(
    id: id,
    name: name,
    category: 'Bar',
    totalReviews: 0,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockRestaurantRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeRestaurantSearchFilters());
  });

  setUp(() {
    repository = MockRestaurantRepository();
    container = ProviderContainer(
      overrides: [restaurantRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é RestaurantsInitial', () {
    expect(
      container.read(restaurantsControllerProvider),
      isA<RestaurantsInitial>(),
    );
  });

  test('loadInitial com resultados -> RestaurantsLoaded', () async {
    when(() => repository.search(any())).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(restaurantsControllerProvider.notifier).loadInitial();

    expect(
      container.read(restaurantsControllerProvider),
      isA<RestaurantsLoaded>(),
    );
  });

  test('loadInitial sem resultados -> RestaurantsEmpty', () async {
    when(() => repository.search(any())).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(restaurantsControllerProvider.notifier).loadInitial();

    expect(
      container.read(restaurantsControllerProvider),
      isA<RestaurantsEmpty>(),
    );
  });

  test('loadInitial com falha -> RestaurantsError', () async {
    when(
      () => repository.search(any()),
    ).thenThrow(const RestaurantRepositoryException('Falha na busca.'));

    await container.read(restaurantsControllerProvider.notifier).loadInitial();

    expect(
      container.read(restaurantsControllerProvider),
      isA<RestaurantsError>(),
    );
  });

  test('search aplica o texto de busca nos filtros', () async {
    RestaurantSearchFilters? capturedFilters;
    when(() => repository.search(any())).thenAnswer((invocation) async {
      capturedFilters =
          invocation.positionalArguments.first as RestaurantSearchFilters;
      return PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      );
    });

    await container
        .read(restaurantsControllerProvider.notifier)
        .search('pizza');

    expect(capturedFilters?.query, 'pizza');
  });
}
