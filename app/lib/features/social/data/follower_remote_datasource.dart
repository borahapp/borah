import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST da tabela
/// `followers` e a resolução de perfis em `profiles` (DV-07). Nenhuma
/// camada acima desta conhece esses detalhes (mesma decisão do DV-03 em
/// diante).
///
/// `followers.follower_id`/`following_id` referenciam `auth.users`, não
/// `profiles` - não há relação (FK) direta entre `followers` e `profiles`
/// que o PostgREST possa usar em um embed. Por isso a listagem de
/// seguidores/seguindo usa duas consultas (buscar os ids em `followers`,
/// depois os perfis em `profiles`), o mesmo padrão já aprovado para o
/// Feed (decisão do DV-07).
class FollowerRemoteDatasource {
  FollowerRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'followers';
  static const _profilesTable = 'profiles';

  /// FASE SOCIAL 2 §11 (AUDITORIA) - campos explícitos em vez de
  /// `.select()` (equivalente a `select *`).
  static const _profileColumns =
      'id,full_name,username,bio,avatar_url,city,state,'
      'followers_count,following_count,created_at,updated_at';

  Future<void> follow(String followerId, String followingId) {
    return _client.from(_table).insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollow(String followerId, String followingId) {
    return _client
        .from(_table)
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final rows = await _client
        .from(_table)
        .select('id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
    return List<Map<String, dynamic>>.from(rows).isNotEmpty;
  }

  /// Retorna os `follower_id` de quem segue [userId], paginado (`limit + 1`
  /// para detectar próxima página, core/models/paged_result.dart).
  Future<List<String>> listFollowerIds(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;
    final rows = await _client
        .from(_table)
        .select('follower_id')
        .eq('following_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['follower_id'] as String).toList();
  }

  Future<List<String>> listFollowingIds(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;
    final rows = await _client
        .from(_table)
        .select('following_id')
        .eq('follower_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['following_id'] as String).toList();
  }

  /// Busca `limit + 1` registros, mesmo mecanismo de
  /// `listFollowerIds`/`RestaurantRemoteDatasource.search`. FASE SOCIAL
  /// 2: aceita busca por "@username" além de nome (`.or()` do
  /// PostgREST) - normaliza o termo antes de montar o filtro.
  Future<List<Map<String, dynamic>>> searchProfiles(
    String query, {
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;
    final normalized = _normalizeSearchTerm(query);
    final rows = await _client
        .from(_profilesTable)
        .select(_profileColumns)
        .or('full_name.ilike.%$normalized%,username.ilike.%$normalized%')
        .order('full_name')
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Remove um "@" inicial (busca por "@victorfrare" deve funcionar como
  /// "victorfrare") e `,`/`(`/`)` - caracteres com significado especial
  /// na sintaxe do filtro `.or()` do PostgREST, que quebrariam a
  /// consulta (ou mudariam seu significado) se um nome/username os
  /// contivesse.
  String _normalizeSearchTerm(String query) {
    final withoutAt = query.startsWith('@') ? query.substring(1) : query;
    return withoutAt.replaceAll(RegExp(r'[,()]'), '');
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

  /// FASE SOCIAL 2 - quais de [candidateIds] o usuário [followerId] já
  /// segue, numa única consulta (ver `FollowerRepository.listFollowingAmong`).
  Future<List<String>> listFollowingAmong(
    String followerId,
    List<String> candidateIds,
  ) async {
    if (candidateIds.isEmpty) return [];
    final rows = await _client
        .from(_table)
        .select('following_id')
        .eq('follower_id', followerId)
        .inFilter('following_id', candidateIds);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['following_id'] as String).toList();
  }
}
