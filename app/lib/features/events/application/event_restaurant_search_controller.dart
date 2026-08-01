import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../restaurants/data/restaurant_repository_impl.dart';
import '../../restaurants/domain/restaurant_repository.dart';
import '../../restaurants/domain/restaurant_search_filters.dart';
import '../presentation/states/event_restaurant_search_status.dart';

/// Depende só de `RestaurantRepository` (dados, sem estado) - nunca de
/// `RestaurantsController` (apresentação, `NotifierProvider` global sem
/// `.autoDispose`, hoje com um único consumidor). Mesmo princípio já
/// usado por `RankingRepositoryImpl -> RestaurantRepository`: reaproveita
/// a lógica de busca sem compartilhar a instância de estado da aba
/// Restaurantes. Sem paginação/filtro de cidade/categoria - fora do
/// escopo desta busca simplificada (ROLÊ-02).
class EventRestaurantSearchController
    extends Notifier<EventRestaurantSearchStatus> {
  @override
  EventRestaurantSearchStatus build() => const EventRestaurantSearchInitial();

  RestaurantRepository get _repository =>
      ref.read(restaurantRepositoryProvider);

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const EventRestaurantSearchInitial();
      return;
    }
    state = const EventRestaurantSearchLoading();
    try {
      final result = await _repository.search(
        RestaurantSearchFilters(query: query, page: 1),
      );
      state = result.items.isEmpty
          ? const EventRestaurantSearchEmpty()
          : EventRestaurantSearchLoaded(result.items);
    } on RestaurantRepositoryException catch (e) {
      state = EventRestaurantSearchError(e.message);
    } catch (_) {
      state = const EventRestaurantSearchError(
        'Não foi possível buscar restaurantes.',
      );
    }
  }
}

final eventRestaurantSearchControllerProvider =
    NotifierProvider<
      EventRestaurantSearchController,
      EventRestaurantSearchStatus
    >(EventRestaurantSearchController.new);
