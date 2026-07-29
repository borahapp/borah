import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Bolha de nota do BORAH — exibição canônica de uma avaliação
/// numérica (0 a 5, ou o que a tela definir).
///
/// Achado real do levantamento do UI-02: a nota era renderizada como
/// `Text` cru em 5 lugares diferentes (`restaurants_search_page.dart`,
/// `favorites_page.dart`, `rankings_page.dart`,
/// `restaurant_detail_page.dart`, `review_detail_page.dart`), com
/// formatação inconsistente entre eles — um dos casos
/// (`rankings_page.dart`) nem checava nulidade e chegava a renderizar
/// a string literal `"null (3)"` quando a nota era nula. Este
/// componente resolve nulidade e formatação em um único lugar.
///
/// Usa `colorScheme.tertiary`/`onTertiary` (Verde BORAH/Preto Uva) —
/// "Verde [...] destaca ações, notas e momentos importantes" (Manual
/// §05). Cor vem de `Theme.of(context)`, nunca de `BrandColors`.
class ScoreBubble extends StatelessWidget {
  const ScoreBubble({
    super.key,
    required this.rating,
    this.reviewCount,
    this.emptyLabel = 'Sem nota',
  });

  /// `null` quando o restaurante/avaliação ainda não tem nota.
  final double? rating;

  /// Quando informado, aparece entre parênteses (ex.: "4.5 (120)").
  final int? reviewCount;

  /// Texto exibido quando [rating] é `null`.
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (rating == null) {
      return Text(emptyLabel, style: theme.textTheme.labelMedium);
    }

    final label = reviewCount == null
        ? rating!.toStringAsFixed(1)
        : '${rating!.toStringAsFixed(1)} ($reviewCount)';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.tertiary,
        borderRadius: AppRadius.radiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: scheme.onTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
