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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: contentPadding,
      title: ScoreBubble(rating: review.rating),
      subtitle: review.comment != null && review.comment!.isNotEmpty
          ? Text(review.comment!)
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
