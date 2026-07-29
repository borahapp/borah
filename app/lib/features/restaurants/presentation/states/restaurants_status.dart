import '../../../../core/models/paged_result.dart';
import '../../domain/restaurant.dart';
import '../../domain/restaurant_search_filters.dart';

/// Estado da listagem/busca de restaurantes (DV-03 §10), sealed class.
/// Prefixo `Restaurants*` para evitar colisão com estados de outros
/// módulos (mesma lição do DV-01/DV-02).
sealed class RestaurantsStatus {
  const RestaurantsStatus();
}

final class RestaurantsInitial extends RestaurantsStatus {
  const RestaurantsInitial();
}

final class RestaurantsLoading extends RestaurantsStatus {
  const RestaurantsLoading();
}

final class RestaurantsSearching extends RestaurantsStatus {
  const RestaurantsSearching(this.filters);

  final RestaurantSearchFilters filters;
}

final class RestaurantsFiltering extends RestaurantsStatus {
  const RestaurantsFiltering(this.filters);

  final RestaurantSearchFilters filters;
}

final class RestaurantsLoaded extends RestaurantsStatus {
  const RestaurantsLoaded(this.result, this.filters);

  final PagedResult<Restaurant> result;
  final RestaurantSearchFilters filters;
}

final class RestaurantsEmpty extends RestaurantsStatus {
  const RestaurantsEmpty(this.filters);

  final RestaurantSearchFilters filters;
}

final class RestaurantsError extends RestaurantsStatus {
  const RestaurantsError(this.message);

  final String message;
}
