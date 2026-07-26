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

/// RC-04E: estado transitório do upload de capa, que mantém os dados já
/// carregados visíveis em vez de substituir a tela inteira por um
/// spinner - mesma técnica já usada em `ReviewDetailPhotoUploading`
/// (RC-02) para o upload de fotos de avaliação.
final class RestaurantDetailCoverUploading extends RestaurantDetailStatus {
  const RestaurantDetailCoverUploading(this.restaurant);

  final Restaurant restaurant;
}

final class RestaurantDetailSaveSuccess extends RestaurantDetailStatus {
  const RestaurantDetailSaveSuccess(this.restaurant);

  final Restaurant restaurant;
}

final class RestaurantDetailError extends RestaurantDetailStatus {
  const RestaurantDetailError(this.message);

  final String message;
}
