import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST das tabelas
/// `user_progress`, `badges`, `user_badges` e do Ranking de Usuários
/// (DV-10). Nenhuma camada acima desta conhece esses detalhes (mesma
/// decisão do DV-03 em diante).
class GamificationRemoteDatasource {
  GamificationRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchProgress(String userId) async {
    final rows = await _client
        .from('user_progress')
        .select()
        .eq('user_id', userId);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? null : list.first;
  }

  Future<List<Map<String, dynamic>>> listAllBadges() async {
    final rows = await _client.from('badges').select().order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Embed direto (`user_badges.badge_id -> badges.id` é uma FK real,
  /// diferente do caso `followers -> profiles` do DV-07).
  Future<List<Map<String, dynamic>>> listEarnedBadges(String userId) async {
    final rows = await _client
        .from('user_badges')
        .select('earned_at, badges(*)')
        .eq('user_id', userId)
        .order('earned_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Busca `limit + 1` registros para permitir detectar se há próxima
  /// página sem depender de uma contagem exata (core/models/paged_result.dart).
  Future<List<Map<String, dynamic>>> listGlobalRanking({
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;
    final rows = await _client
        .from('user_progress')
        .select()
        .order('points', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<String>> _fetchFollowingIds(String userId) async {
    final rows = await _client
        .from('followers')
        .select('following_id')
        .eq('follower_id', userId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['following_id'] as String).toList();
  }

  /// Duas consultas (buscar `following_id`, depois `user_progress` via
  /// `IN`) - mesmo padrão já aprovado no DV-09/Feed, sem VIEW/RPC nova.
  Future<List<Map<String, dynamic>>> listFriendsRanking(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final followingIds = await _fetchFollowingIds(userId);
    if (followingIds.isEmpty) return [];

    final from = (page - 1) * limit;
    final to = from + limit;
    final rows = await _client
        .from('user_progress')
        .select()
        .inFilter('user_id', followingIds)
        .order('points', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// 2ª ocorrência do padrão "buscar ids -> buscar relacionados" com
  /// resolução de nome (a 1ª foi `AdminRoleRemoteDatasource.fetchNamesByIds`
  /// no DV-08) - registrada como observação, extração só na 3ª (decisão do DV-10).
  Future<Map<String, String?>> fetchNamesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', ids);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['id'] as String: row['full_name'] as String?,
    };
  }
}
