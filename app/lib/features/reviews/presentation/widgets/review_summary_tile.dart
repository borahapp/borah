import 'package:flutter/material.dart';

import '../../../../design_system/components/feedback/score_bubble.dart';
import '../../domain/review.dart';

/// Renderização de uma avaliação como item de lista - extraído quando a
/// 3ª tela (`ReviewsListPage`, `FeedPage` do DV-07, e o "Avaliações" do
/// `PublicProfilePage`) precisou do mesmo layout (nota + comentário),
/// mesmo critério já aplicado ao `ImagePickerService` no DV-03.
///
/// RC-03 Sprint 1 (`RC03_DESIGN_GAP.md §3`): a nota passou a usar
/// `ScoreBubble` em vez de `Text` cru — era o único ponto do app que não
/// usava o componente já existente para isso (`RC03_UI_AUDIT.md §6`).
/// Sem `reviewCount`, `ScoreBubble` renderiza exatamente
/// `rating.toStringAsFixed(1)` (a mesma string de antes) — os testes de
/// widget que dependem de `find.text('4.5')` (`feed_page_test.dart`)
/// continuam válidos sem alteração, verificado antes desta mudança.
///
/// 2B.3: autor/restaurante/data (achado P2/P3 - ausentes até então)
/// lidos direto de [review], já resolvidos pelo repositório
/// (`ReviewRepositoryImpl._mapRow`) - este widget nunca acessa o
/// datasource, só o que já chega pronto no objeto `Review`. Campos são
/// `null` quando o repositório não os resolveu (nunca quebra o layout).
class ReviewSummaryTile extends StatelessWidget {
  const ReviewSummaryTile({
    super.key,
    required this.review,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  final Review review;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAuthorOrRestaurant =
        (review.authorFullName?.isNotEmpty ?? false) ||
        (review.restaurantName?.isNotEmpty ?? false);

    return ListTile(
      contentPadding: contentPadding,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScoreBubble(rating: review.rating),
          const SizedBox(width: 8),
          Text(_formatDate(review.createdAt), style: theme.textTheme.bodySmall),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasAuthorOrRestaurant)
            Text(
              [
                if (review.authorFullName?.isNotEmpty ?? false)
                  review.authorFullName!,
                if (review.restaurantName?.isNotEmpty ?? false)
                  review.restaurantName!,
              ].join(' · '),
              style: theme.textTheme.labelMedium,
            ),
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(review.comment!),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
