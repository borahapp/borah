import 'package:app/core/services/location_service.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/nearby_restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/search/application/nearby_restaurants_controller.dart';
import 'package:app/features/search/presentation/states/nearby_restaurants_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationService extends Mock implements LocationService {}

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

NearbyRestaurant _nearby({String id = 'r-1', double distanceKm = 1.2}) {
  return NearbyRestaurant(
    restaurantId: id,
    name: 'Bar do Zé',
    category: 'Bar',
    totalReviews: 10,
    distanceKm: distanceKm,
  );
}

void main() {
  late MockLocationService locationService;
  late MockRestaurantRepository restaurantRepository;
  late ProviderContainer container;

  setUp(() {
    locationService = MockLocationService();
    restaurantRepository = MockRestaurantRepository();
    container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(locationService),
        restaurantRepositoryProvider.overrideWithValue(restaurantRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é NearbyRestaurantsInitial', () {
    expect(
      container.read(nearbyRestaurantsControllerProvider),
      isA<NearbyRestaurantsInitial>(),
    );
  });

  test('load com sucesso -> NearbyRestaurantsLoaded', () async {
    when(() => locationService.getCurrentLocation()).thenAnswer(
      (_) async => const LocationCoordinates(latitude: -23.5, longitude: -46.6),
    );
    when(
      () => restaurantRepository.listNearby(
        latitude: -23.5,
        longitude: -46.6,
        limit: 10,
      ),
    ).thenAnswer((_) async => [_nearby()]);

    await container.read(nearbyRestaurantsControllerProvider.notifier).load();

    final status = container.read(nearbyRestaurantsControllerProvider);
    expect(status, isA<NearbyRestaurantsLoaded>());
    expect(
      (status as NearbyRestaurantsLoaded).restaurants.single.restaurantId,
      'r-1',
    );
  });

  test('load sem restaurantes próximos -> NearbyRestaurantsEmpty', () async {
    when(() => locationService.getCurrentLocation()).thenAnswer(
      (_) async => const LocationCoordinates(latitude: -23.5, longitude: -46.6),
    );
    when(
      () => restaurantRepository.listNearby(
        latitude: -23.5,
        longitude: -46.6,
        limit: 10,
      ),
    ).thenAnswer((_) async => []);

    await container.read(nearbyRestaurantsControllerProvider.notifier).load();

    expect(
      container.read(nearbyRestaurantsControllerProvider),
      isA<NearbyRestaurantsEmpty>(),
    );
  });

  test('serviço de localização desligado -> NearbyRestaurantsServiceDisabled', () async {
    when(
      () => locationService.getCurrentLocation(),
    ).thenThrow(LocationServiceDisabledException());

    await container.read(nearbyRestaurantsControllerProvider.notifier).load();

    expect(
      container.read(nearbyRestaurantsControllerProvider),
      isA<NearbyRestaurantsServiceDisabled>(),
    );
  });

  test('permissão negada -> NearbyRestaurantsPermissionDenied', () async {
    when(
      () => locationService.getCurrentLocation(),
    ).thenThrow(LocationPermissionDeniedException());

    await container.read(nearbyRestaurantsControllerProvider.notifier).load();

    expect(
      container.read(nearbyRestaurantsControllerProvider),
      isA<NearbyRestaurantsPermissionDenied>(),
    );
  });

  test('falha ao buscar restaurantes -> NearbyRestaurantsError', () async {
    when(() => locationService.getCurrentLocation()).thenAnswer(
      (_) async => const LocationCoordinates(latitude: -23.5, longitude: -46.6),
    );
    when(
      () => restaurantRepository.listNearby(
        latitude: -23.5,
        longitude: -46.6,
        limit: 10,
      ),
    ).thenThrow(const RestaurantRepositoryException('Falha ao carregar.'));

    await container.read(nearbyRestaurantsControllerProvider.notifier).load();

    expect(
      container.read(nearbyRestaurantsControllerProvider),
      isA<NearbyRestaurantsError>(),
    );
  });
}
