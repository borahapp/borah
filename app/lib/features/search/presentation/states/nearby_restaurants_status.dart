import '../../../restaurants/domain/nearby_restaurant.dart';

/// Estado de "Perto de você" (Item G - sugestão por localização em
/// Explorar), sealed class - mesmo padrão do resto do app.
sealed class NearbyRestaurantsStatus {
  const NearbyRestaurantsStatus();
}

final class NearbyRestaurantsInitial extends NearbyRestaurantsStatus {
  const NearbyRestaurantsInitial();
}

final class NearbyRestaurantsLoading extends NearbyRestaurantsStatus {
  const NearbyRestaurantsLoading();
}

final class NearbyRestaurantsLoaded extends NearbyRestaurantsStatus {
  const NearbyRestaurantsLoaded(this.restaurants);

  final List<NearbyRestaurant> restaurants;
}

/// Nenhum restaurante com coordenadas dentro do raio - distinto de erro,
/// não é um estado de falha.
final class NearbyRestaurantsEmpty extends NearbyRestaurantsStatus {
  const NearbyRestaurantsEmpty();
}

/// GPS/localização desligada no dispositivo.
final class NearbyRestaurantsServiceDisabled extends NearbyRestaurantsStatus {
  const NearbyRestaurantsServiceDisabled();
}

/// Usuário negou a permissão de localização.
final class NearbyRestaurantsPermissionDenied extends NearbyRestaurantsStatus {
  const NearbyRestaurantsPermissionDenied();
}

final class NearbyRestaurantsError extends NearbyRestaurantsStatus {
  const NearbyRestaurantsError(this.message);

  final String message;
}
