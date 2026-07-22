import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../feedback/score_bubble.dart';
import 'app_card.dart';

/// Card de restaurante do BORAH.
///
/// Achado real do levantamento do UI-02: hoje não existe nenhum
/// "card" de restaurante — `restaurants_search_page.dart` e
/// `favorites_page.dart` renderizam a mesma linha (nome, categoria,
/// cidade, nota) como `ListTile` cru, com a lógica de nota duplicada
/// entre os dois arquivos. Este componente recebe dados simples (não
/// a entidade `Restaurant`), para não acoplar o Design System à
/// camada de features.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.name,
    required this.category,
    this.city,
    this.rating,
    this.reviewCount,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String category;
  final String? city;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onTap;

  /// Widget opcional à direita (ex.: ícone de favorito).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      category,
      if (city != null && city!.isNotEmpty) city,
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ScoreBubble(rating: rating, reviewCount: reviewCount),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
