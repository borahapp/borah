import '../../../../core/models/paged_result.dart';
import '../../../restaurants/domain/restaurant.dart';

/// Estado da listagem/edição administrativa de restaurantes (DV-08),
/// sealed class.
sealed class AdminRestaurantsStatus {
  const AdminRestaurantsStatus();
}

final class AdminRestaurantsInitial extends AdminRestaurantsStatus {
  const AdminRestaurantsInitial();
}

final class AdminRestaurantsLoading extends AdminRestaurantsStatus {
  const AdminRestaurantsLoading();
}

final class AdminRestaurantsLoaded extends AdminRestaurantsStatus {
  const AdminRestaurantsLoaded(this.result);

  final PagedResult<Restaurant> result;
}

final class AdminRestaurantsEmpty extends AdminRestaurantsStatus {
  const AdminRestaurantsEmpty();
}

/// Salvando uma edição/arquivamento - mantém a lista anterior visível.
final class AdminRestaurantsSaving extends AdminRestaurantsStatus {
  const AdminRestaurantsSaving(this.result);

  final PagedResult<Restaurant> result;
}

final class AdminRestaurantsError extends AdminRestaurantsStatus {
  const AdminRestaurantsError(this.message);

  final String message;
}
