import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula o acesso de leitura a `group_members` para o ranking do
/// grupo (BLOCO 5). Sem RPC/view - mesmo padrão de TODO ranking já
/// existente no projeto (`restaurants.average_rating`/`total_reviews`,
/// `user_progress.points`): consulta direta com `order by` nas colunas
/// já denormalizadas pelos triggers da migration
/// `20260801110000_add_group_ranking_columns.sql`.
class GroupRankingRemoteDatasource {
  GroupRankingRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _membersTable = 'group_members';
  static const _profilesTable = 'profiles';

  Future<List<Map<String, dynamic>>> listByGroup(String groupId) async {
    final rows = await _client
        .from(_membersTable)
        .select('user_id,events_count,reviews_count,average_score')
        .eq('group_id', groupId)
        .order('events_count', ascending: false)
        .order('reviews_count', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Mesmo método/assinatura de `GroupRemoteDatasource.fetchProfilesByIds`
  /// - duplicado aqui, mesma decisão já tomada para todo par
  /// datasource/`profiles` do projeto.
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_profilesTable)
        .select()
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }
}
