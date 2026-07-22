import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';

/// Estado vazio do BORAH.
///
/// Achado real do levantamento do UI-02: 13 mensagens de estado vazio
/// diferentes (ex.: "Nenhuma avaliação ainda.", "Você ainda não tem
/// favoritos.") são hoje um `Center(child: Text('...'))` isolado,
/// repetido em cada arquivo, sem ícone nem ação. Este componente
/// centraliza a estrutura visual - a mensagem em si continua sendo
/// responsabilidade de cada tela (nenhuma tela foi migrada nesta
/// rodada).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon, this.action});

  final String message;
  final IconData? icon;

  /// Ação opcional (ex.: `AppPrimaryButton` "Adicionar restaurante").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
