import '../../reviews/domain/review.dart';

/// Autor de um item do Feed (FASE SOCIAL 4) - só os campos que o
/// `SocialFeedCard` precisa exibir, já resolvidos junto com o item (evita
/// uma consulta de perfil por card). Duplica o formato de `UserProfile`
/// (DV-02) por decisão consciente - mesmo padrão de desacoplamento entre
/// features já usado por `FeedRepositoryImpl`/`FollowerRepositoryImpl`
/// (cada um com seu próprio mapeamento de linha para entidade).
class FeedActor {
  const FeedActor({
    required this.id,
    required this.fullName,
    required this.username,
    required this.avatarUrl,
  });

  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
}

/// Item do Feed Social (FASE SOCIAL 4) - união dos 3 tipos de publicação
/// aprovados nesta fase: avaliação, badge conquistado, entrada em grupo
/// público. `feedKey` (não o `id` da linha de origem) identifica o item na
/// `ListView` e desempata a ordenação - `Review.id`/`UserBadge.id`/
/// `group_members.id` são espaços de UUID independentes que podem colidir
/// entre si.
sealed class FeedItem {
  const FeedItem();

  String get feedKey;
  DateTime get createdAt;
  FeedActor get actor;
}

/// "Fulano avaliou [Restaurante]" - fonte: `reviews`.
class FeedReviewItem extends FeedItem {
  const FeedReviewItem({
    required this.review,
    required this.actor,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantCoverImage,
    required this.likesCount,
    required this.isLikedByUser,
    required this.commentsCount,
  });

  final Review review;
  @override
  final FeedActor actor;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantCoverImage;

  /// Resolvidos em lote por página do Feed (nunca 1 consulta por card) -
  /// ver `FeedRemoteDatasource.fetchLikedReviewIds`/`fetchCommentCounts`.
  final int likesCount;
  final bool isLikedByUser;
  final int commentsCount;

  @override
  String get feedKey => 'review:${review.id}';
  @override
  DateTime get createdAt => review.createdAt;
}

/// "Fulano conquistou a badge [Nome]" - fonte: `user_badges`.
class FeedBadgeItem extends FeedItem {
  const FeedBadgeItem({
    required this.id,
    required this.actor,
    required this.badgeCode,
    required this.badgeName,
    required this.badgeDescription,
    required this.earnedAt,
  });

  final String id;
  @override
  final FeedActor actor;
  final String badgeCode;
  final String badgeName;
  final String? badgeDescription;
  final DateTime earnedAt;

  @override
  String get feedKey => 'badge:$id';
  @override
  DateTime get createdAt => earnedAt;
}

/// "Fulano entrou no grupo [Nome]" - fonte: RPC `recent_public_group_joins`
/// (só grupos `visibility = 'public'`, nunca a tabela `group_members`
/// direta).
class FeedGroupJoinItem extends FeedItem {
  const FeedGroupJoinItem({
    required this.memberId,
    required this.actor,
    required this.groupId,
    required this.groupName,
    required this.groupPhotoUrl,
    required this.memberCount,
    required this.joinedAt,
    required this.viewerIsMember,
  });

  final String memberId;
  @override
  final FeedActor actor;
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final int memberCount;
  final DateTime joinedAt;

  /// Se quem está vendo o Feed também é membro deste grupo - decide o
  /// destino da navegação (`/groups/:id` vs `/groups/:id/preview`), mesmo
  /// critério já usado por `SearchPage`/`GroupResultTile` (FASE SOCIAL 3).
  final bool viewerIsMember;

  @override
  String get feedKey => 'group_join:$memberId';
  @override
  DateTime get createdAt => joinedAt;
}

/// "[Pessoa] criou um rolê em [Restaurante]" (FEED-04) - fonte: `events`,
/// filtrada por `organizer_id IN relevantIds` (mesmos `relevantIds` já
/// calculados para reviews/badges). Sem filtro de `group_id` no client -
/// a RLS `events_select_members` (`is_group_member(auth.uid(),
/// group_id)`) já garante que só rolês de grupos dos quais o viewer é
/// membro voltam da consulta; "seguir" o organizador nunca é suficiente
/// sozinho (auditoria FEED-04, confirmado via simulação de RLS).
///
/// Sem `title`/`description`/`visibility` - nenhum desses campos existe
/// em `events` (auditoria FEED-04, seção 2) - não inventados aqui.
class FeedEventItem extends FeedItem {
  const FeedEventItem({
    required this.eventId,
    required this.actor,
    required this.groupId,
    required this.groupName,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantCoverImage,
    required this.scheduledAt,
    required this.status,
    required this.confirmedCount,
    required this.createdAt,
  });

  final String eventId;
  @override
  final FeedActor actor;
  final String groupId;
  final String groupName;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantCoverImage;
  final DateTime scheduledAt;

  /// Valor real do banco (`scheduled`/`completed`/`cancelled` -
  /// ROLÊ-01), mesmo campo de `Event.status`.
  final String status;

  /// `event_attendances` com `status = 'confirmed'` - mesma técnica de
  /// embed filtrado já usada por `Event.confirmedCount`
  /// (`EventRemoteDatasource._eventColumns`).
  final int confirmedCount;

  /// Quando o rolê foi criado (`events.created_at`) - usado para
  /// ordenação, não `scheduled_at` (quando vai acontecer). O Feed é uma
  /// timeline do que foi publicado agora, mesmo critério de
  /// Review/Badge/GroupJoin (auditoria FEED-04, seção 12).
  @override
  final DateTime createdAt;

  @override
  String get feedKey => 'event:$eventId';
}
