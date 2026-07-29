import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/favorite_sort_by.dart';

/// Encapsula toda a construção de consultas PostgREST da tabela
/// `favorites`, incluindo o embed com `restaurants` (evita N+1 sem
/// acoplar este módulo a `RestaurantRepository` - decisão do DV-06).
/// Nenhuma camada acima desta conhece esses detalhes.
class FavoriteRemoteDatasource {
  FavoriteRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'favorites';

  /// Busca `limit + 1` registros para permitir detectar se há próxima
  /// página sem depender de uma contagem exata (core/models/paged_result.dart).
  /// Considera apenas restaurantes `status = 'active'` e não excluídos
  /// (DV-06 decisão 7). Ordenação por avaliação reutiliza exatamente os
  /// critérios de desempate do DV-05 §6 (decisão 8).
  Future<List<Map<String, dynamic>>> listForUser(
    String userId, {
    String? query,
    String? city,
    String? category,
    required FavoriteSortBy sortBy,
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    var builder = _client
        .from(_table)
        .select('created_at, restaurants!inner(*)')
        .eq('user_id', userId)
        .eq('restaurants.status', 'active')
        .isFilter('restaurants.deleted_at', null);

    if (query != null && query.isNotEmpty) {
      builder = builder.ilike('restaurants.name', '%$query%');
    }
    if (city != null && city.isNotEmpty) {
      builder = builder.eq('restaurants.city', city);
    }
    if (category != null && category.isNotEmpty) {
      builder = builder.eq('restaurants.category', category);
    }

    final ordered = switch (sortBy) {
      FavoriteSortBy.name => builder.order(
        'name',
        referencedTable: 'restaurants',
      ),
      FavoriteSortBy.rating =>
        builder
            .order(
              'average_rating',
              referencedTable: 'restaurants',
              ascending: false,
            )
            .order(
              'total_reviews',
              referencedTable: 'restaurants',
              ascending: false,
            )
            .order(
              'updated_at',
              referencedTable: 'restaurants',
              ascending: false,
            )
            .order('name', referencedTable: 'restaurants'),
      FavoriteSortBy.date => builder.order('created_at', ascending: false),
    };

    final rows = await ordered.range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addFavorite(String userId, String restaurantId) {
    return _client.from(_table).insert({
      'user_id': userId,
      'restaurant_id': restaurantId,
    });
  }

  Future<void> removeFavorite(String userId, String restaurantId) {
    return _client
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('restaurant_id', restaurantId);
  }

  Future<bool> isFavorited(String userId, String restaurantId) async {
    final rows = await _client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .eq('restaurant_id', restaurantId);
    return List<Map<String, dynamic>>.from(rows).isNotEmpty;
  }
}
