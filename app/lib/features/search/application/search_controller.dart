import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/data/group_repository_impl.dart';
import '../../restaurants/data/restaurant_repository_impl.dart';
import '../../restaurants/domain/restaurant_search_filters.dart';
import '../../social/data/follower_repository_impl.dart';
import '../presentation/states/search_status.dart';

/// Controller da Pesquisa (FASE SOCIAL 1-3). Sem repositório próprio:
/// chama `FollowerRepository`/`GroupRepository`/`RestaurantRepository`
/// diretamente, já que não há lógica de busca nova a encapsular (os 3
/// métodos já existem cada um na sua feature).
class SearchController extends Notifier<SearchStatus> {
  @override
  SearchStatus build() => const SearchInitial();

  static const _limit = 20;
  int _requestId = 0;

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final requestId = ++_requestId;
    if (trimmed.isEmpty) {
      state = const SearchInitial();
      return;
    }

    state = const SearchLoading();
    try {
      final peopleFuture = ref
          .read(followerRepositoryProvider)
          .searchProfiles(trimmed, page: 1, limit: _limit);
      final groupsFuture = ref
          .read(groupRepositoryProvider)
          .search(trimmed, page: 1, limit: _limit);
      final restaurantsFuture = ref
          .read(restaurantRepositoryProvider)
          .search(
            RestaurantSearchFilters(query: trimmed, page: 1, limit: _limit),
          );

      final people = await peopleFuture;
      final groups = await groupsFuture;
      final restaurants = await restaurantsFuture;
      if (requestId != _requestId) return;

      state = SearchLoaded(
        people: people,
        groups: groups,
        restaurants: restaurants,
      );
    } catch (_) {
      if (requestId != _requestId) return;
      state = const SearchError('Não foi possível buscar. Tente novamente.');
    }
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchStatus>(SearchController.new);
