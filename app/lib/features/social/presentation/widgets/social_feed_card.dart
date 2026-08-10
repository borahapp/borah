import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/score_bubble.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../users/presentation/widgets/profile_avatar.dart';
import '../../application/feed_like_controller.dart';
import '../../application/feed_review_photo_provider.dart';
import '../../domain/feed_item.dart';

/// Card social do Feed (FASE SOCIAL 4) - substitui o `ReviewSummaryTile`
/// (que continua existindo, sem alteração, para `ReviewsListPage`/
/// `PublicProfilePage`) exclusivamente dentro do Feed. Referência de UX,
/// não visual: avatar → contexto → conteúdo → imagem → ações → timestamp,
/// mesma composição de qualquer rede social, com a identidade do BORAH
/// (`Theme.of(context)`, `AppCard`, `ScoreBubble`, `AppBadge`).
class SocialFeedCard extends StatelessWidget {
  const SocialFeedCard({
    super.key,
    required this.item,
    required this.currentUserId,
  });

  final FeedItem item;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      FeedReviewItem it => _ReviewCard(item: it, currentUserId: currentUserId),
      FeedBadgeItem it => _BadgeCard(item: it),
      FeedGroupJoinItem it => _GroupJoinCard(item: it),
    };
  }
}

String _relativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} d';
  if (diff.inDays < 365) return '${(diff.inDays / 7).floor()} sem';
  return '${(diff.inDays / 365).floor()} a';
}

/// Cabeçalho comum aos 3 tipos de card: avatar + nome + @username +
/// timestamp, tudo tocável para o perfil do autor.
class _FeedCardHeader extends StatelessWidget {
  const _FeedCardHeader({
    required this.actor,
    required this.createdAt,
    required this.onTap,
  });

  final FeedActor actor;
  final DateTime createdAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = actor.fullName?.isNotEmpty == true
        ? actor.fullName!
        : 'Sem nome';

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            ProfileAvatar(avatarPath: actor.avatarUrl, radius: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (actor.username != null && actor.username!.isNotEmpty)
                    Text(
                      '@${actor.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _relativeTime(createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusPill,
      child: ConstrainedBox(
        // Alvo de toque mínimo de acessibilidade (48x48) - o conteúdo
        // (ícone + rótulo) é bem menor, então o botão precisa de área de
        // toque extra além do que o conteúdo visual ocupa.
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "[Pessoa] avaliou [Restaurante]" - avatar, contexto, nota, comentário,
/// foto (lazy), likes/comentários.
class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.item, required this.currentUserId});

  final FeedReviewItem item;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final likeArgs = FeedLikeArgs(
      reviewId: item.review.id,
      initialIsLiked: item.isLikedByUser,
      initialLikesCount: item.likesCount,
    );
    final likeState = ref.watch(feedLikeControllerProvider(likeArgs));
    final comment = item.review.comment;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: AppCard(
        onTap: () => context.push('/reviews/${item.review.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeedCardHeader(
              actor: item.actor,
              createdAt: item.createdAt,
              onTap: () => context.push('/users/${item.actor.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: AppRadius.radiusSm,
              onTap: () => context.push('/restaurants/${item.restaurantId}'),
              child: ConstrainedBox(
                // Alvo de toque mínimo de acessibilidade (48 de altura) -
                // o texto sozinho é bem mais baixo que isso.
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      children: [
                        const TextSpan(text: 'avaliou '),
                        TextSpan(
                          text: item.restaurantName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ScoreBubble(rating: item.review.rating),
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(comment, style: theme.textTheme.bodyMedium),
            ],
            if (item.review.photosCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              _LazyReviewPhoto(reviewId: item.review.id),
            ],
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                _ActionButton(
                  icon: likeState.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  iconColor: likeState.isLiked ? theme.colorScheme.error : null,
                  label: '${likeState.likesCount}',
                  onTap: () => ref
                      .read(feedLikeControllerProvider(likeArgs).notifier)
                      .toggle(currentUserId),
                ),
                const SizedBox(width: AppSpacing.md),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: '${item.commentsCount}',
                  onTap: () =>
                      context.push('/reviews/${item.review.id}/comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolve e exibe a primeira foto da avaliação sob demanda (ver
/// `feedReviewPhotoProvider` - lazy por construção via `ListView.builder`,
/// nunca pré-carregada na consulta principal do Feed).
class _LazyReviewPhoto extends ConsumerWidget {
  const _LazyReviewPhoto({required this.reviewId});

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(feedReviewPhotoProvider(reviewId));
    final theme = Theme.of(context);

    return photoAsync.when(
      data: (url) => url == null
          ? const SizedBox.shrink()
          : ClipRRect(
              borderRadius: AppRadius.radiusMd,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
      loading: () => ClipRRect(
        borderRadius: AppRadius.radiusMd,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(color: theme.colorScheme.surfaceContainerHighest),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// "[Pessoa] conquistou a badge [Nome]".
class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.item});

  final FeedBadgeItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: AppCard(
        onTap: () => context.push('/users/${item.actor.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeedCardHeader(
              actor: item.actor,
              createdAt: item.createdAt,
              onTap: () => context.push('/users/${item.actor.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'conquistou uma nova badge',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: theme.colorScheme.onTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.badgeName, style: theme.textTheme.titleSmall),
                      if (item.badgeDescription != null &&
                          item.badgeDescription!.isNotEmpty)
                        Text(
                          item.badgeDescription!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "[Pessoa] entrou no grupo [Grupo]" - só nome/foto/contagem de membros
/// (nunca a lista de membros), ação "Ver grupo".
class _GroupJoinCard extends StatelessWidget {
  const _GroupJoinCard({required this.item});

  final FeedGroupJoinItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memberLabel = item.memberCount == 1
        ? '1 membro'
        : '${item.memberCount} membros';
    final groupRoute = item.viewerIsMember
        ? '/groups/${item.groupId}'
        : '/groups/${item.groupId}/preview';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: AppCard(
        onTap: () => context.push(groupRoute),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeedCardHeader(
              actor: item.actor,
              createdAt: item.createdAt,
              onTap: () => context.push('/users/${item.actor.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('entrou no grupo', style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: item.groupPhotoUrl != null
                      ? NetworkImage(item.groupPhotoUrl!)
                      : null,
                  child: item.groupPhotoUrl == null
                      ? const Icon(Icons.groups)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.groupName, style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const AppBadge(label: 'Público'),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            memberLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(groupRoute),
                  child: const Text('Ver grupo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
