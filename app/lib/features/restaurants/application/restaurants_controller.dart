import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/restaurant_repository_impl.dart';
import '../domain/restaurant_repository.dart';
import '../domain/restaurant_search_filters.dart';
import '../presentation/states/restaurants_status.dart';

/// Fluxo simples RestaurantRepository -> Controller (mesmo padrão do
/// DV-01/DV-02), sem use cases intermediários. O controller só monta um
/// `RestaurantSearchFilters` e nunca constrói consulta PostgREST (isso
/// fica inteiramente em `data/`, decisão do DV-03).
class RestaurantsController extends Notifier<RestaurantsStatus> {
  @override
  RestaurantsStatus build() => const RestaurantsInitial();

  RestaurantRepository get _repository =>
      ref.read(restaurantRepositoryProvider);

  Future<void> loadInitial() {
    return _run(const RestaurantSearchFilters(), const RestaurantsLoading());
  }

  Future<void> search(String query) {
    final filters = _currentFilters().copyWith(query: query, page: 1);
    return _run(filters, RestaurantsSearching(filters));
  }

  Future<void> applyFilters({String? city, String? category}) {
    final filters = _currentFilters().copyWith(
      city: city,
      category: category,
      page: 1,
    );
    return _run(filters, RestaurantsFiltering(filters));
  }

  RestaurantSearchFilters _currentFilters() {
    final current = state;
    return switch (current) {
      RestaurantsLoaded(:final filters) ||
      RestaurantsSearching(:final filters) ||
      RestaurantsFiltering(:final filters) ||
      RestaurantsEmpty(:final filters) => filters,
      _ => const RestaurantSearchFilters(),
    };
  }

  Future<void> _run(
    RestaurantSearchFilters filters,
    RestaurantsStatus loadingState,
  ) async {
    state = loadingState;
    try {
      final result = await _repository.search(filters);
      state = result.items.isEmpty
          ? RestaurantsEmpty(filters)
          : RestaurantsLoaded(result, filters);
    } on RestaurantRepositoryException catch (e) {
      state = RestaurantsError(e.message);
    } catch (_) {
      state = const RestaurantsError(
        'Não foi possível carregar os restaurantes.',
      );
    }
  }
}

final restaurantsControllerProvider =
    NotifierProvider<RestaurantsController, RestaurantsStatus>(
      RestaurantsController.new,
    );
