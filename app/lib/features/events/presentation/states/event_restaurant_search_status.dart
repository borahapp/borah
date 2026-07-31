import '../../../restaurants/domain/restaurant.dart';

/// Estado da busca de restaurante embutida na criação de rolê
/// (ROLÊ-02) - mesmo shape de `FavoritesStatus`/`GroupsListStatus`.
/// Deliberadamente distinto de `RestaurantsStatus` (usado por
/// `restaurants_search_page.dart`): aquele é global/singleton
/// (`NotifierProvider` sem `.autoDispose`, único consumidor hoje);
/// reutilizá-lo aqui acoplaria esta tela ao estado da aba Restaurantes
/// (buscas de uma tela sobrescreveriam a outra). Este estado é próprio
/// e escopado só a este fluxo.
sealed class EventRestaurantSearchStatus {
  const EventRestaurantSearchStatus();
}

final class EventRestaurantSearchInitial extends EventRestaurantSearchStatus {
  const EventRestaurantSearchInitial();
}

final class EventRestaurantSearchLoading extends EventRestaurantSearchStatus {
  const EventRestaurantSearchLoading();
}

final class EventRestaurantSearchLoaded extends EventRestaurantSearchStatus {
  const EventRestaurantSearchLoaded(this.restaurants);

  final List<Restaurant> restaurants;
}

final class EventRestaurantSearchEmpty extends EventRestaurantSearchStatus {
  const EventRestaurantSearchEmpty();
}

final class EventRestaurantSearchError extends EventRestaurantSearchStatus {
  const EventRestaurantSearchError(this.message);

  final String message;
}
