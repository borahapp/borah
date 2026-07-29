import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Bottom Sheet do BORAH.
///
/// Achado real do levantamento do UI-02: `showModalBottomSheet` não é
/// usado em nenhuma tela hoje. Este componente fica pronto para o
/// primeiro uso futuro (ex.: seletor de opções, ações rápidas).
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  /// Abre o bottom sheet com o cantos superiores arredondados
  /// (`AppRadius.xl`) e `isScrollControlled` (permite conteúdo alto,
  /// ex.: formulários com teclado aberto).
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) =>
          AppBottomSheet(title: title, child: builder(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
