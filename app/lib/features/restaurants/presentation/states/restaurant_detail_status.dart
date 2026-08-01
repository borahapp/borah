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

/// QA (BLOCO 9): [restaurant] preserva os dados já carregados quando o
/// erro vem de uma ação sobre uma tela já aberta (ex.: upload de capa
/// que falhou) - `null` só no caso de falha do `load()` inicial, sem
/// nada ainda para mostrar. Mesmo padrão de `GroupDetailError`/
/// `EventDetailError` (evita que uma falha de ação apague a tela
/// inteira do restaurante, regressão que o comentário de
/// `RestaurantDetailCoverUploading` já dizia evitar, mas só cobria o
/// estado de upload, não o de erro).
final class RestaurantDetailError extends RestaurantDetailStatus {
  const RestaurantDetailError(this.message, [this.restaurant]);

  final String message;
  final Restaurant? restaurant;
}
