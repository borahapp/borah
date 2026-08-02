import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';

/// Card genérico do BORAH — envolve o `Card` do Material (raio/elevação
/// já vêm de `CardThemeData` em `core/theme/app_theme.dart`), só
/// acrescenta o preenchimento interno padrão e o toque opcional.
/// Base para os cards compostos (`RestaurantCard`, `RankingCard`).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;

  /// Preenchimento interno. Por padrão, `AppSpacing.lg` em todos os
  /// lados.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
