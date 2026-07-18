import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/restaurant_repository_impl.dart';
import '../domain/restaurant_repository.dart';
import '../presentation/states/restaurant_detail_status.dart';

class RestaurantDetailController extends Notifier<RestaurantDetailStatus> {
  @override
  RestaurantDetailStatus build() => const RestaurantDetailInitial();

  RestaurantRepository get _repository =>
      ref.read(restaurantRepositoryProvider);

  Future<void> load(String id) async {
    state = const RestaurantDetailLoading();
    try {
      final restaurant = await _repository.getById(id);
      state = RestaurantDetailLoaded(restaurant);
    } on RestaurantRepositoryException catch (e) {
      state = RestaurantDetailError(e.message);
    } catch (_) {
      state = const RestaurantDetailError(
        'Não foi possível carregar o restaurante.',
      );
    }
  }

  Future<void> create({
    required String createdBy,
    required String name,
    required String category,
    String? description,
    String? address,
    String? city,
    String? stateProvince,
    double? latitude,
    double? longitude,
  }) async {
    state = const RestaurantDetailSaving();
    try {
      final restaurant = await _repository.create(
        createdBy: createdBy,
        name: name,
        category: category,
        description: description,
        address: address,
        city: city,
        stateProvince: stateProvince,
        latitude: latitude,
        longitude: longitude,
      );
      state = RestaurantDetailSaveSuccess(restaurant);
    } on RestaurantRepositoryException catch (e) {
      state = RestaurantDetailError(e.message);
    } catch (_) {
      state = const RestaurantDetailError(
        'Não foi possível cadastrar o restaurante.',
      );
    }
  }

  Future<void> updateCoverImage(
    String restaurantId, {
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    state = const RestaurantDetailSaving();
    try {
      final restaurant = await _repository.updateCoverImage(
        restaurantId,
        bytes: bytes,
        fileExtension: fileExtension,
      );
      state = RestaurantDetailSaveSuccess(restaurant);
    } on RestaurantRepositoryException catch (e) {
      state = RestaurantDetailError(e.message);
    } catch (_) {
      state = const RestaurantDetailError('Não foi possível atualizar a capa.');
    }
  }
}

final restaurantDetailControllerProvider =
    NotifierProvider<RestaurantDetailController, RestaurantDetailStatus>(
      RestaurantDetailController.new,
    );
