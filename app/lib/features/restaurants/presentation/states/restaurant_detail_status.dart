import '../../domain/restaurant.dart';

/// Estado de um restaurante individual (Detalhes/Cadastro, DV-03 §6) -
/// separado do `RestaurantsStatus` (listagem/busca), pois trata de um
/// único registro por vez, assim como o `UserProfileStatus` do DV-02.
sealed class RestaurantDetailStatus {
  const RestaurantDetailStatus();
}

final class RestaurantDetailInitial extends RestaurantDetailStatus {
  const RestaurantDetailInitial();
}

final class RestaurantDetailLoading extends RestaurantDetailStatus {
  const RestaurantDetailLoading();
}

final class RestaurantDetailLoaded extends RestaurantDetailStatus {
  const RestaurantDetailLoaded(this.restaurant);

  final Restaurant restaurant;
}

final class RestaurantDetailSaving extends RestaurantDetailStatus {
  const RestaurantDetailSaving();
}

final class RestaurantDetailSaveSuccess extends RestaurantDetailStatus {
  const RestaurantDetailSaveSuccess(this.restaurant);

  final Restaurant restaurant;
}

final class RestaurantDetailError extends RestaurantDetailStatus {
  const RestaurantDetailError(this.message);

  final String message;
}
