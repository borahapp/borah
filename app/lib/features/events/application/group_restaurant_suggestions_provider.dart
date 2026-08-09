import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../restaurants/data/restaurant_repository_impl.dart';
import '../../restaurants/domain/restaurant.dart';

/// RC-03 F13 - restaurantes favoritados por membros do grupo, ainda não
/// visitados pelo grupo (ver `suggest_group_restaurants`,
/// `20260809130000_add_suggest_group_restaurants.sql`). Puramente
/// informativo - `create_event_page.dart` continua permitindo buscar
/// qualquer restaurante manualmente, a sugestão é só um atalho.
final groupRestaurantSuggestionsProvider =
    FutureProvider.family<List<Restaurant>, String>((ref, groupId) {
      return ref.watch(restaurantRepositoryProvider).suggestForGroup(groupId);
    });
