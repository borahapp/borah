import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula a consulta do Feed (DV-07, decisão 3): duas consultas
/// simples - primeiro os `following_id` do usuário em `followers`, depois
/// as avaliações desses usuários em `reviews` via `IN (...)`. Sem VIEW,
/// RPC, Materialized View ou Edge Function nesta versão (decisão
/// explícita). Considera apenas `reviews.deleted_at IS NULL` e
/// `restaurants.status = 'active'` (decisão do DV-07).
class FeedRemoteDatasource {
  FeedRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<List<String>> _fetchFollowingIds(String userId) async {
    final rows = await _client
        .from('followers')
        .select('following_id')
        .eq('follower_id', userId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['following_id'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> listForUser(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final followingIds = await _fetchFollowingIds(userId);
    if (followingIds.isEmpty) return [];

    final from = (page - 1) * limit;
    final to = from + limit;

    final rows = await _client
        .from('reviews')
        .select('*, restaurants!inner(status, deleted_at)')
        .inFilter('user_id', followingIds)
        .isFilter('deleted_at', null)
        .eq('restaurants.status', 'active')
        .isFilter('restaurants.deleted_at', null)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(rows);
  }
}
