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

  int _requestId = 0;

  /// ROLE-SEARCH-02: agora chamado tanto pelo `onSubmit` (Enter) quanto
  /// pelo `onChanged` debounçado da tela - duas buscas podem ficar em
  /// voo ao mesmo tempo (ex.: "Madero" ainda respondendo quando
  /// "McDonald" já foi digitado). `_requestId` garante que só a
  /// resposta da busca mais recente é aplicada ao estado, mesmo que uma
  /// busca antiga responda depois - mesmo padrão já usado em
  /// `GooglePlaceSearchController.search`.
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _requestId++;
      state = const EventRestaurantSearchInitial();
      return;
    }
    final requestId = ++_requestId;
    state = const EventRestaurantSearchLoading();
    try {
      final result = await _repository.search(
        RestaurantSearchFilters(query: query, page: 1),
      );
      if (requestId != _requestId) return;
      state = result.items.isEmpty
          ? const EventRestaurantSearchEmpty()
          : EventRestaurantSearchLoaded(result.items);
    } on RestaurantRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = EventRestaurantSearchError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
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
