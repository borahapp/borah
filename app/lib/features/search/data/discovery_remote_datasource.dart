import 'package:supabase_flutter/supabase_flutter.dart';

/// Consultas cruas para "Você pode conhecer" (FASE SOCIAL 2). Nenhuma
/// tabela/RPC nova - reaproveita `group_members`/`followers`/`profiles`
/// já existentes, mesmas consultas descritas na AUDITORIA — FASE SOCIAL
/// 2 §8/§13/§14. Duplica pequenas consultas já parecidas em
/// `GroupRemoteDatasource`/`FollowerRemoteDatasource` deliberadamente -
/// mesma decisão consciente do DV-07 (`FollowerRepositoryImpl._mapRow`)
/// de manter `features/search` desacoplado das outras features.
class DiscoveryRemoteDatasource {
  DiscoveryRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _groupMembersTable = 'group_members';
  static const _followersTable = 'followers';
  static const _profilesTable = 'profiles';

  static const _profileColumns =
      'id,full_name,username,bio,avatar_url,city,state,'
      'followers_count,following_count,created_at,updated_at';

  /// Grupos dos quais [userId] é membro - a RLS de `group_members`
  /// (`is_group_member`) já permite essa leitura sem restrição adicional.
  Future<List<String>> fetchMyGroupIds(String userId) async {
    final rows = await _client
        .from(_groupMembersTable)
        .select('group_id')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['group_id'] as String).toList();
  }

  /// Outros membros de [groupIds] (exclui [excludeUserId]) - a mesma
  /// policy `group_members_select_members` permite ver todas as linhas
  /// de um grupo do qual o usuário já é membro, não só a própria linha
  /// (ver AUDITORIA — FASE SOCIAL 2 §8).
  Future<List<String>> fetchGroupMemberIds(
    List<String> groupIds, {
    required String excludeUserId,
  }) async {
    if (groupIds.isEmpty) return [];
    final rows = await _client
        .from(_groupMembersTable)
        .select('user_id')
        .inFilter('group_id', groupIds)
        .neq('user_id', excludeUserId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['user_id'] as String).toSet().toList();
  }

  /// Até [limit] pessoas que [userId] já segue - usadas como "sementes"
  /// da prioridade 2 (amigos de amigos), não a lista completa de quem
  /// ele segue.
  Future<List<String>> fetchFollowingSeeds(
    String userId, {
    required int limit,
  }) async {
    final rows = await _client
        .from(_followersTable)
        .select('following_id')
        .eq('follower_id', userId)
        .limit(limit);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['following_id'] as String).toList();
  }

  /// Seguidores das "sementes" acima - candidatos de amigos-de-amigos.
  /// [limit] aplicado sobre o total (não por semente), para manter a
  /// consulta previsível independente de quantas sementes existirem.
  Future<List<String>> fetchFollowerIdsOf(
    List<String> seedIds, {
    required int limit,
  }) async {
    if (seedIds.isEmpty) return [];
    final rows = await _client
        .from(_followersTable)
        .select('follower_id')
        .inFilter('following_id', seedIds)
        .limit(limit);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['follower_id'] as String).toList();
  }

  /// Quais de [candidateIds] o usuário [userId] já segue - usada para
  /// excluir quem já é seguido da lista de sugestões.
  Future<Set<String>> fetchFollowingAmong(
    String userId,
    List<String> candidateIds,
  ) async {
    if (candidateIds.isEmpty) return {};
    final rows = await _client
        .from(_followersTable)
        .select('following_id')
        .eq('follower_id', userId)
        .inFilter('following_id', candidateIds);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['following_id'] as String).toSet();
  }

  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_profilesTable)
        .select(_profileColumns)
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }
}
