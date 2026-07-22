import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../feedback/score_bubble.dart';
import 'app_card.dart';

/// Card de avaliação do BORAH.
///
/// Achado real do levantamento do UI-02: `review_summary_tile.dart`
/// (usado por `ReviewsListPage`, `FeedPage` e `PublicProfilePage`) já
/// mostra nota + comentário, mas como `ListTile` (nota como título,
/// comentário como subtítulo, sem contagem de curtidas). Este
/// componente é a versão em card, reaproveitando `ScoreBubble` em vez
/// de repetir a formatação de nota.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.rating,
    this.comment,
    this.likesCount,
    this.onTap,
  });

  final double rating;
  final String? comment;
  final int? likesCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ScoreBubble(rating: rating),
              if (likesCount != null) ...[
                const Spacer(),
                Icon(Icons.favorite, size: 16, color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.xs),
                Text('$likesCount', style: theme.textTheme.labelMedium),
              ],
            ],
          ),
          if (comment != null && comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(comment!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
