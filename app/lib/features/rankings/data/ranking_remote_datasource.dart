import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula as 2 consultas do Ranking multi-escopo (Item F) que não
/// cabem em `RestaurantRepository` (escopo `global`, que continua lá -
/// é uma consulta pura da tabela `restaurants`): `personal` lê a tabela
/// `reviews` (não é dono desta tabela `RestaurantRemoteDatasource`, nem
/// deveria ser), `group` chama a RPC `get_group_restaurant_ranking`
/// (`20261125121000`). Mesmo princípio de isolamento de
/// `FavoriteRemoteDatasource`/`RestaurantRemoteDatasource`.
class RankingRemoteDatasource {
  RankingRemoteDatasource(this._client);

  final SupabaseClient _client;

  /// Embed `!inner` (mesmo padrão de `FavoriteRemoteDatasource.listForUser`)
  /// - obrigatório aqui porque os filtros de localização abaixo (`.eq`
  /// em colunas de `restaurants`) só funcionam com o join interno; o
  /// embed opcional usado em `ReviewRemoteDatasource` (BETA-RELEASE-03)
  /// não se aplica - lá o problema era perder a *review* quando o
  /// restaurante não resolvia, o que não é um risco real aqui (toda
  /// review tem `restaurant_id` não-nulo com FK obrigatória).
  Future<List<Map<String, dynamic>>> listPersonal({
    required String userId,
    String? city,
    String? state,
    String? country,
    String? category,
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    var builder = _client
        .from('reviews')
        .select('rating, restaurants!inner(*)')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .eq('restaurants.status', 'active')
        .isFilter('restaurants.deleted_at', null);

    if (city != null && city.isNotEmpty) {
      builder = builder.eq('restaurants.city', city);
    }
    if (state != null && state.isNotEmpty) {
      builder = builder.eq('restaurants.state', state);
    }
    if (country != null && country.isNotEmpty) {
      builder = builder.eq('restaurants.country', country);
    }
    if (category != null && category.isNotEmpty) {
      builder = builder.eq('restaurants.category', category);
    }

    final rows = await builder
        .order('rating', ascending: false)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> listByGroup({
    required String groupId,
    String? city,
    String? state,
    String? country,
    String? category,
    required int limit,
    required int offset,
  }) async {
    final rows = await _client.rpc(
      'get_group_restaurant_ranking',
      params: {
        'p_group_id': groupId,
        'p_city': city,
        'p_state': state,
        'p_country': country,
        'p_category': category,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
