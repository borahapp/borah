import 'package:flutter/material.dart';

import '../../domain/review.dart';

/// Renderização de uma avaliação como item de lista - extraído quando a
/// 3ª tela (`ReviewsListPage`, `FeedPage` do DV-07, e o "Avaliações" do
/// `PublicProfilePage`) precisou do mesmo layout (nota + comentário),
/// mesmo critério já aplicado ao `ImagePickerService` no DV-03.
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
      title: Text(review.rating.toStringAsFixed(1)),
      subtitle: review.comment != null && review.comment!.isNotEmpty
          ? Text(review.comment!)
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
