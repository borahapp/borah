import 'package:app/core/models/paged_result.dart';
import 'package:app/features/events/application/event_restaurant_search_controller.dart';
import 'package:app/features/events/presentation/states/event_restaurant_search_status.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/domain/restaurant_search_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class FakeRestaurantSearchFilters extends Fake
    implements RestaurantSearchFilters {}

Restaurant _restaurant({String name = 'Bar do Zé'}) {
  return Restaurant(
    id: 'r-1',
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

  test('estado inicial é EventRestaurantSearchInitial', () {
    expect(
      container.read(eventRestaurantSearchControllerProvider),
      isA<EventRestaurantSearchInitial>(),
    );
  });

  group('search', () {
    test('query vazia -> permanece/retorna a Initial, sem chamar o repository', () async {
      await container
          .read(eventRestaurantSearchControllerProvider.notifier)
          .search('   ');

      expect(
        container.read(eventRestaurantSearchControllerProvider),
        isA<EventRestaurantSearchInitial>(),
      );
      verifyNever(() => repository.search(any()));
    });

    test('resultado não vazio -> EventRestaurantSearchLoaded', () async {
      when(() => repository.search(any())).thenAnswer(
        (_) async => PagedResult<Restaurant>(
          items: [_restaurant()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await container
          .read(eventRestaurantSearchControllerProvider.notifier)
          .search('bar');

      final status = container.read(eventRestaurantSearchControllerProvider);
      expect(status, isA<EventRestaurantSearchLoaded>());
      expect(
        (status as EventRestaurantSearchLoaded).restaurants,
        hasLength(1),
      );
    });

    test('resultado vazio -> EventRestaurantSearchEmpty', () async {
      when(() => repository.search(any())).thenAnswer(
        (_) async => const PagedResult<Restaurant>(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await container
          .read(eventRestaurantSearchControllerProvider.notifier)
          .search('inexistente');

      expect(
        container.read(eventRestaurantSearchControllerProvider),
        isA<EventRestaurantSearchEmpty>(),
      );
    });

    test('falha com RestaurantRepositoryException -> EventRestaurantSearchError com a mensagem original', () async {
      when(() => repository.search(any())).thenThrow(
        const RestaurantRepositoryException('Falha ao buscar.'),
      );

      await container
          .read(eventRestaurantSearchControllerProvider.notifier)
          .search('bar');

      final status = container.read(eventRestaurantSearchControllerProvider);
      expect(status, isA<EventRestaurantSearchError>());
      expect(
        (status as EventRestaurantSearchError).message,
        'Falha ao buscar.',
      );
    });
  });
}
