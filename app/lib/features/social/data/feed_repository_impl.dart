import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../reviews/domain/review.dart';
import '../domain/feed_item.dart';
import '../domain/feed_repository.dart';
import 'feed_remote_datasource.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._datasource);

  final FeedRemoteDatasource _datasource;

  @override
  Future<PagedResult<FeedItem>> listForYou(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _guard(
      () => _compose(
        viewerId: userId,
        page: page,
        limit: limit,
        fetchRelevantIds: () => _relevantIdsForYou(userId),
        includeGroupJoins: true,
      ),
    );
  }

  @override
  Future<PagedResult<FeedItem>> listFollowing(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _guard(
      () => _compose(
        viewerId: userId,
        page: page,
        limit: limit,
        fetchRelevantIds: () => _relevantIdsFollowing(userId),
        includeGroupJoins: false,
      ),
    );
  }

  /// "Eu mesmo" + "Pessoas que sigo" (FEED-03 acrescenta o próprio
  /// usuário - mesmo raciocínio de [_relevantIdsForYou]).
  Future<List<String>> _relevantIdsFollowing(String userId) async {
    final following = await _datasource.fetchFollowingIds(userId);
    return {userId, ...following}.toList();
  }

  /// "Eu mesmo" + "Pessoas que sigo" + "pessoas relacionadas através de
  /// grupos em comum"/"pessoas dos meus grupos" (FASE SOCIAL 4, ajuste 1;
  /// FEED-03 acrescenta o próprio usuário) - as duas últimas descrevem a
  /// mesma relação (membros de um grupo do qual também participo), por
  /// isso uma única fonte (`fetchGroupPeerIds`) atende as duas.
  ///
  /// FEED-03: sem incluir [userId] aqui, as próprias reviews/badges do
  /// usuário nunca eram buscadas (a causa raiz não era um filtro de
  /// exclusão - era esta lista de candidatos nunca conter o próprio id).
  Future<List<String>> _relevantIdsForYou(String userId) async {
    final following = await _datasource.fetchFollowingIds(userId);
    final peers = await _datasource.fetchGroupPeerIds(userId);
    return {userId, ...following, ...peers}.toList();
  }

  /// Model A (FASE SOCIAL 4, decisão de arquitetura): sem tabela
  /// `activities`, sem VIEW/RPC de agregação - cada fonte é buscada
  /// separadamente (top [page]*[limit], capado em 100) e o resultado é
  /// mesclado e ordenado em memória por `(createdAt desc, feedKey desc)`.
  /// Buscar `page*limit` de CADA fonte (não incrementalmente por OFFSET
  /// por fonte) garante que a página final está correta mesmo cruzando
  /// fontes heterogêneas - o "top N global" de um merge de listas já
  /// ordenadas está sempre contido no "top N de cada lista".
  ///
  /// Sem preenchimento com conteúdo de qualquer usuário da plataforma
  /// (decisão explícita, ajuste 1 do plano aprovado) - se as fontes abaixo
  /// não renderem itens suficientes, a página só tem o que existe; a
  /// `FeedPage` mostra um estado de descoberta nesse caso, nunca completa
  /// a lista com avaliações não relacionadas ao usuário.
  Future<PagedResult<FeedItem>> _compose({
    required String viewerId,
    required int page,
    required int limit,
    required Future<List<String>> Function() fetchRelevantIds,
    required bool includeGroupJoins,
  }) async {
    final candidateLimit = (page * limit).clamp(limit, 100);

    final relevantIds = await fetchRelevantIds();

    final reviewRows = relevantIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _datasource.fetchReviewsByUsers(
            relevantIds,
            limit: candidateLimit,
          );
    final badgeRows = relevantIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _datasource.fetchBadgesByUsers(
            relevantIds,
            limit: candidateLimit,
          );
    final groupJoinRows = includeGroupJoins
        ? await _datasource.fetchRecentPublicGroupJoins(limit: candidateLimit)
        : <Map<String, dynamic>>[];

    final reviewIds = reviewRows.map((row) => row['id'] as String).toList();
    final likedIds = await _datasource.fetchLikedReviewIds(viewerId, reviewIds);
    final commentCounts = await _datasource.fetchCommentCounts(reviewIds);

    final myGroupIds = groupJoinRows.isEmpty
        ? const <String>{}
        : await _datasource.fetchMyGroupIds(viewerId);

    // `reviews`/`user_badges` não têm FK direta para `profiles` (ambas
    // referenciam `auth.users`), então o autor não vem embutido na linha -
    // 1 única consulta em lote resolve os perfis de ambas as fontes juntas
    // (nunca 1 consulta por review/badge).
    final authorIds = {
      ...reviewRows.map((row) => row['user_id'] as String),
      ...badgeRows.map((row) => row['user_id'] as String),
    }.toList();
    final profileRows = authorIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _datasource.fetchProfilesByIds(authorIds);
    final profilesById = {
      for (final row in profileRows) row['id'] as String: row,
    };

    final items = <FeedItem>[
      ...reviewRows.map(
        (row) => _mapReviewRow(row, likedIds, commentCounts, profilesById),
      ),
      ...badgeRows.map((row) => _mapBadgeRow(row, profilesById)),
      ...groupJoinRows.map((row) => _mapGroupJoinRow(row, myGroupIds)),
    ];

    items.sort((a, b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      if (byDate != 0) return byDate;
      return b.feedKey.compareTo(a.feedKey);
    });

    final from = (page - 1) * limit;
    if (from >= items.length) {
      return PagedResult<FeedItem>(
        items: const [],
        page: page,
        limit: limit,
        hasNextPage: false,
      );
    }
    final to = (from + limit).clamp(0, items.length);

    return PagedResult<FeedItem>(
      items: items.sublist(from, to),
      page: page,
      limit: limit,
      hasNextPage: items.length > to,
    );
  }

  /// Monta o autor a partir de [userId] + o mapa resolvido em lote em
  /// `_compose` - se [userId] não tiver perfil correspondente (sem crash),
  /// o autor ainda aparece (com o id), só sem nome/username/avatar.
  FeedActor _mapActor(
    String userId,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    final profile = profilesById[userId];
    return FeedActor(
      id: userId,
      fullName: profile?['full_name'] as String?,
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  FeedReviewItem _mapReviewRow(
    Map<String, dynamic> row,
    Set<String> likedIds,
    Map<String, int> commentCounts,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    final id = row['id'] as String;
    final userId = row['user_id'] as String;
    final restaurant = row['restaurants'] as Map<String, dynamic>;
    return FeedReviewItem(
      review: Review(
        id: id,
        restaurantId: row['restaurant_id'] as String,
        userId: userId,
        rating: (row['rating'] as num).toDouble(),
        ambienceScore: (row['ambience_score'] as num?)?.toDouble(),
        serviceScore: (row['service_score'] as num?)?.toDouble(),
        foodScore: (row['food_score'] as num?)?.toDouble(),
        costBenefitScore: (row['cost_benefit_score'] as num?)?.toDouble(),
        comment: row['comment'] as String?,
        likesCount: row['likes_count'] as int,
        photosCount: row['photos_count'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      ),
      actor: _mapActor(userId, profilesById),
      restaurantId: restaurant['id'] as String,
      restaurantName: restaurant['name'] as String,
      restaurantCoverImage: restaurant['cover_image'] as String?,
      likesCount: row['likes_count'] as int,
      isLikedByUser: likedIds.contains(id),
      commentsCount: commentCounts[id] ?? 0,
    );
  }

  FeedBadgeItem _mapBadgeRow(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    final badge = row['badges'] as Map<String, dynamic>;
    return FeedBadgeItem(
      id: row['id'] as String,
      actor: _mapActor(row['user_id'] as String, profilesById),
      badgeCode: badge['code'] as String,
      badgeName: badge['name'] as String,
      badgeDescription: badge['description'] as String?,
      earnedAt: DateTime.parse(row['earned_at'] as String),
    );
  }

  FeedGroupJoinItem _mapGroupJoinRow(
    Map<String, dynamic> row,
    Set<String> myGroupIds,
  ) {
    final groupId = row['group_id'] as String;
    return FeedGroupJoinItem(
      memberId: row['member_id'] as String,
      actor: FeedActor(
        id: row['user_id'] as String,
        fullName: row['full_name'] as String?,
        username: row['username'] as String?,
        avatarUrl: row['avatar_url'] as String?,
      ),
      groupId: groupId,
      groupName: row['group_name'] as String,
      groupPhotoUrl: row['group_photo_url'] as String?,
      memberCount: row['member_count'] as int,
      joinedAt: DateTime.parse(row['joined_at'] as String),
      viewerIsMember: myGroupIds.contains(groupId),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw FeedRepositoryException(e.message);
    }
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FeedRepositoryImpl(FeedRemoteDatasource(client));
});
