import 'dart:typed_data';

import 'package:app/features/restaurants/application/restaurant_detail_controller.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/presentation/states/restaurant_detail_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

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
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockRestaurantRepository();
    container = ProviderContainer(
      overrides: [restaurantRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é RestaurantDetailInitial', () {
    expect(
      container.read(restaurantDetailControllerProvider),
      isA<RestaurantDetailInitial>(),
    );
  });

  group('load', () {
    test('sucesso -> RestaurantDetailLoaded', () async {
      when(
        () => repository.getById('r-1'),
      ).thenAnswer((_) async => _restaurant());

      await container
          .read(restaurantDetailControllerProvider.notifier)
          .load('r-1');

      expect(
        container.read(restaurantDetailControllerProvider),
        isA<RestaurantDetailLoaded>(),
      );
    });

    test('falha -> RestaurantDetailError', () async {
      when(
        () => repository.getById('r-1'),
      ).thenThrow(const RestaurantRepositoryException('Não encontrado.'));

      await container
          .read(restaurantDetailControllerProvider.notifier)
          .load('r-1');

      expect(
        container.read(restaurantDetailControllerProvider),
        isA<RestaurantDetailError>(),
      );
    });
  });

  group('create', () {
    test('sucesso -> RestaurantDetailSaveSuccess', () async {
      when(
        () => repository.create(
          createdBy: any(named: 'createdBy'),
          name: any(named: 'name'),
          category: any(named: 'category'),
          description: any(named: 'description'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          stateProvince: any(named: 'stateProvince'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => _restaurant());

      await container
          .read(restaurantDetailControllerProvider.notifier)
          .create(createdBy: 'user-1', name: 'Bar do Zé', category: 'Bar');

      expect(
        container.read(restaurantDetailControllerProvider),
        isA<RestaurantDetailSaveSuccess>(),
      );
    });

    test('falha -> RestaurantDetailError', () async {
      when(
        () => repository.create(
          createdBy: any(named: 'createdBy'),
          name: any(named: 'name'),
          category: any(named: 'category'),
          description: any(named: 'description'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          stateProvince: any(named: 'stateProvince'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenThrow(const RestaurantRepositoryException('Nome duplicado.'));

      await container
          .read(restaurantDetailControllerProvider.notifier)
          .create(createdBy: 'user-1', name: 'Bar do Zé', category: 'Bar');

      expect(
        container.read(restaurantDetailControllerProvider),
        isA<RestaurantDetailError>(),
      );
    });
  });

  group('updateCoverImage', () {
    test('sucesso -> RestaurantDetailSaveSuccess', () async {
      when(
        () => repository.updateCoverImage(
          'r-1',
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      ).thenAnswer((_) async => _restaurant());

      await container
          .read(restaurantDetailControllerProvider.notifier)
          .updateCoverImage('r-1', bytes: Uint8List(0), fileExtension: 'jpg');

      expect(
        container.read(restaurantDetailControllerProvider),
        isA<RestaurantDetailSaveSuccess>(),
      );
    });
  });
}
