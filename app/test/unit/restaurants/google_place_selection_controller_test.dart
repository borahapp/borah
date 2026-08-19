import 'package:app/features/restaurants/application/google_place_selection_controller.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/google_place_result.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/presentation/states/google_place_selection_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

GooglePlaceResult _place({
  String placeId = 'ChIJ123',
  String name = 'Madero',
  List<String> types = const ['restaurant', 'food', 'point_of_interest'],
}) {
  return GooglePlaceResult(
    placeId: placeId,
    name: name,
    address: 'Av. XXXXX, Jundiaí - SP',
    latitude: -23.1,
    longitude: -46.8,
    types: types,
  );
}

Restaurant _restaurant({String id = 'r-1', String? googlePlaceId = 'ChIJ123'}) {
  return Restaurant(
    id: id,
    name: 'Madero',
    category: 'Restaurant',
    totalReviews: 0,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    googlePlaceId: googlePlaceId,
  );
}

void main() {
  late MockRestaurantRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockRestaurantRepository();
    container = ProviderContainer(
      overrides: [restaurantRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é GooglePlaceSelectionInitial', () {
    expect(
      container.read(googlePlaceSelectionControllerProvider),
      isA<GooglePlaceSelectionInitial>(),
    );
  });

  test('restaurante existente (mesmo google_place_id) é reaproveitado, '
      'nunca criado de novo', () async {
    when(
      () => repository.findByGooglePlaceId('ChIJ123'),
    ).thenAnswer((_) async => _restaurant());

    await container
        .read(googlePlaceSelectionControllerProvider.notifier)
        .selectPlace(_place(), createdBy: 'user-1');

    final status = container.read(googlePlaceSelectionControllerProvider);
    expect(status, isA<GooglePlaceSelectionResolved>());
    final resolved = status as GooglePlaceSelectionResolved;
    expect(resolved.wasCreated, isFalse);
    expect(resolved.restaurant.id, 'r-1');
    verifyNever(
      () => repository.create(
        createdBy: any(named: 'createdBy'),
        name: any(named: 'name'),
        category: any(named: 'category'),
      ),
    );
  });

  test(
    'restaurante novo é criado com dados do Google, incluindo google_place_id',
    () async {
      when(
        () => repository.findByGooglePlaceId('ChIJ123'),
      ).thenAnswer((_) async => null);
      when(
        () => repository.create(
          createdBy: 'user-1',
          name: 'Madero',
          category: 'Restaurant',
          address: 'Av. XXXXX, Jundiaí - SP',
          latitude: -23.1,
          longitude: -46.8,
          googlePlaceId: 'ChIJ123',
        ),
      ).thenAnswer((_) async => _restaurant());

      await container
          .read(googlePlaceSelectionControllerProvider.notifier)
          .selectPlace(_place(), createdBy: 'user-1');

      final status = container.read(googlePlaceSelectionControllerProvider);
      expect(status, isA<GooglePlaceSelectionResolved>());
      expect((status as GooglePlaceSelectionResolved).wasCreated, isTrue);
    },
  );

  test(
    'categoria sugerida usa o primeiro tipo não-genérico, título-caso',
    () async {
      when(
        () => repository.findByGooglePlaceId(any()),
      ).thenAnswer((_) async => null);
      when(
        () => repository.create(
          createdBy: any(named: 'createdBy'),
          name: any(named: 'name'),
          category: captureAny(named: 'category'),
          address: any(named: 'address'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          googlePlaceId: any(named: 'googlePlaceId'),
        ),
      ).thenAnswer((_) async => _restaurant());

      await container
          .read(googlePlaceSelectionControllerProvider.notifier)
          .selectPlace(
            _place(types: const ['point_of_interest', 'cafe', 'establishment']),
            createdBy: 'user-1',
          );

      final captured = verify(
        () => repository.create(
          createdBy: any(named: 'createdBy'),
          name: any(named: 'name'),
          category: captureAny(named: 'category'),
          address: any(named: 'address'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          googlePlaceId: any(named: 'googlePlaceId'),
        ),
      ).captured;
      expect(captured.single, 'Cafe');
    },
  );

  test('só tipos genéricos -> categoria padrão "Restaurante"', () async {
    when(
      () => repository.findByGooglePlaceId(any()),
    ).thenAnswer((_) async => null);
    when(
      () => repository.create(
        createdBy: any(named: 'createdBy'),
        name: any(named: 'name'),
        category: captureAny(named: 'category'),
        address: any(named: 'address'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        googlePlaceId: any(named: 'googlePlaceId'),
      ),
    ).thenAnswer((_) async => _restaurant());

    await container
        .read(googlePlaceSelectionControllerProvider.notifier)
        .selectPlace(
          _place(types: const ['point_of_interest', 'establishment', 'food']),
          createdBy: 'user-1',
        );

    final captured = verify(
      () => repository.create(
        createdBy: any(named: 'createdBy'),
        name: any(named: 'name'),
        category: captureAny(named: 'category'),
        address: any(named: 'address'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        googlePlaceId: any(named: 'googlePlaceId'),
      ),
    ).captured;
    expect(captured.single, 'Restaurante');
  });

  test('falha na resolução -> GooglePlaceSelectionError', () async {
    when(
      () => repository.findByGooglePlaceId(any()),
    ).thenThrow(const RestaurantRepositoryException('falhou'));

    await container
        .read(googlePlaceSelectionControllerProvider.notifier)
        .selectPlace(_place(), createdBy: 'user-1');

    final status = container.read(googlePlaceSelectionControllerProvider);
    expect(status, isA<GooglePlaceSelectionError>());
    expect((status as GooglePlaceSelectionError).message, 'falhou');
  });
}
