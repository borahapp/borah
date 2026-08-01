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
    // RC-04E: mantém os dados já carregados visíveis durante o upload,
    // em vez de substituir a tela inteira por um spinner (regressão vs.
    // o padrão já usado para fotos de avaliação, RC-02).
    final previous = state;
    final previousRestaurant = switch (previous) {
      RestaurantDetailLoaded(:final restaurant) ||
      RestaurantDetailSaveSuccess(:final restaurant) ||
      RestaurantDetailCoverUploading(:final restaurant) => restaurant,
      _ => null,
    };
    state = previousRestaurant == null
        ? const RestaurantDetailSaving()
        : RestaurantDetailCoverUploading(previousRestaurant);
    try {
      final restaurant = await _repository.updateCoverImage(
        restaurantId,
        bytes: bytes,
        fileExtension: fileExtension,
      );
      state = RestaurantDetailSaveSuccess(restaurant);
    } on RestaurantRepositoryException catch (e) {
      // QA (BLOCO 9): mantém o restaurante já carregado visível mesmo
      // quando o upload falha - antes, uma falha aqui apagava a tela
      // inteira (nome/categoria/descrição/endereço), não só a foto.
      state = RestaurantDetailError(e.message, previousRestaurant);
    } catch (_) {
      state = RestaurantDetailError(
        'Não foi possível atualizar a capa.',
        previousRestaurant,
      );
    }
  }
}

final restaurantDetailControllerProvider =
    NotifierProvider<RestaurantDetailController, RestaurantDetailStatus>(
      RestaurantDetailController.new,
    );
