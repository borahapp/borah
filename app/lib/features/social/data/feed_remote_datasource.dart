import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula todas as consultas do Feed Social (FASE SOCIAL 4) - Model A
/// dinâmico, sem VIEW, RPC de agregação, Materialized View ou tabela
/// `activities` (decisão explícita desta fase). A única RPC usada é
/// `recent_public_group_joins`, que expõe um recorte seguro de
/// `group_members` (só grupos `public`) - `group_members` continua
/// fechada ao cliente para qualquer outra consulta direta.
class FeedRemoteDatasource {
  FeedRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _reviewsSelect =
      '*, restaurants!inner(id, name, cover_image, status, deleted_at)';

  static const _badgesSelect = '*, badges!inner(code, name, description)';

  static const _profilesSelect = 'id, full_name, username, avatar_url';

  Future<List<String>> fetchFollowingIds(String userId) async {
    final rows = await _client
        .from('followers')
        .select('following_id')
        .eq('follower_id', userId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['following_id'] as String).toList();
  }

  /// "Pessoas relacionadas através de grupos em comum" / "pessoas dos meus
  /// grupos" (FASE SOCIAL 4, ajuste 1) - mesma relação social, 2 consultas:
  /// meus grupos, depois os demais membros desses grupos. A policy
  /// `group_members_select_members` (GROUP-01) já permite ver todas as
  /// linhas de um grupo do qual o usuário é membro, não só a própria.
  Future<List<String>> fetchGroupPeerIds(String userId) async {
    final myGroupRows = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);
    final myGroupIds = List<Map<String, dynamic>>.from(
      myGroupRows,
    ).map((row) => row['group_id'] as String).toList();
    if (myGroupIds.isEmpty) return [];

    final peerRows = await _client
        .from('group_members')
        .select('user_id')
        .inFilter('group_id', myGroupIds)
        .neq('user_id', userId);
    return List<Map<String, dynamic>>.from(
      peerRows,
    ).map((row) => row['user_id'] as String).toSet().toList();
  }

  /// Ids de grupo dos quais [userId] já é membro - usado só para marcar
  /// `FeedGroupJoinItem.viewerIsMember` (decide `/groups/:id` vs
  /// `/groups/:id/preview`), nunca para ler a lista de membros de outrem.
  Future<Set<String>> fetchMyGroupIds(String userId) async {
    final rows = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['group_id'] as String).toSet();
  }

  /// Avaliações de [userIds], mais recentes primeiro, até [limit]. Mesmos
  /// filtros do Feed anterior (restaurante ativo, avaliação não excluída)
  /// - agora também traz o perfil do autor e o nome/capa do restaurante,
  /// necessários para o `SocialFeedCard`.
  Future<List<Map<String, dynamic>>> fetchReviewsByUsers(
    List<String> userIds, {
    required int limit,
  }) async {
    if (userIds.isEmpty) return [];
    final rows = await _client
        .from('reviews')
        .select(_reviewsSelect)
        .inFilter('user_id', userIds)
        .isFilter('deleted_at', null)
        .eq('restaurants.status', 'active')
        .isFilter('restaurants.deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Badges conquistados por [userIds], mais recentes primeiro.
  /// `user_badges`/`badges` são públicas (sem filtro extra de RLS).
  Future<List<Map<String, dynamic>>> fetchBadgesByUsers(
    List<String> userIds, {
    required int limit,
  }) async {
    if (userIds.isEmpty) return [];
    final rows = await _client
        .from('user_badges')
        .select(_badgesSelect)
        .inFilter('user_id', userIds)
        .order('earned_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Entradas recentes em grupos `public` (RPC `security definer` -
  /// `group_members` de grupo `private` nunca é alcançada, mesmo se o
  /// usuário atual for membro dele).
  /// Perfis dos autores de [ids] (reviews/badges), buscados à parte -
  /// `reviews.user_id`/`user_badges.user_id` referenciam `auth.users`, não
  /// `profiles`, então não há FK direta que o PostgREST possa usar num
  /// embed (mesma limitação documentada em `FollowerRemoteDatasource`).
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from('profiles')
        .select(_profilesSelect)
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchRecentPublicGroupJoins({
    required int limit,
  }) async {
    final rows = await _client.rpc(
      'recent_public_group_joins',
      params: {'p_limit': limit, 'p_offset': 0},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Quais de [reviewIds] o usuário [userId] já curtiu - 1 consulta em
  /// lote por página do Feed, nunca 1 por card (evita N+1).
  Future<Set<String>> fetchLikedReviewIds(
    String userId,
    List<String> reviewIds,
  ) async {
    if (reviewIds.isEmpty) return {};
    final rows = await _client
        .from('review_likes')
        .select('review_id')
        .eq('user_id', userId)
        .inFilter('review_id', reviewIds);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['review_id'] as String).toSet();
  }

  /// Contagem de comentários (não excluídos) de [reviewIds] - também 1
  /// consulta em lote, contada no cliente por `review_id`.
  Future<Map<String, int>> fetchCommentCounts(List<String> reviewIds) async {
    if (reviewIds.isEmpty) return {};
    final rows = await _client
        .from('comments')
        .select('review_id')
        .isFilter('deleted_at', null)
        .inFilter('review_id', reviewIds);
    final counts = <String, int>{};
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      final reviewId = row['review_id'] as String;
      counts[reviewId] = (counts[reviewId] ?? 0) + 1;
    }
    return counts;
  }
}
