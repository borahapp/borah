import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../buttons/app_outlined_button.dart';

/// Estado de erro do BORAH (RC-02, Quick Win).
///
/// Achado real da RC-01: o padrão `Center(child: Text(message))` sem
/// nenhuma ação de retry se repete em praticamente toda tela do app.
/// Este componente centraliza a estrutura visual - a mensagem em si
/// continua sendo responsabilidade de cada tela.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
  });

  final String message;
  final IconData icon;

  /// Ação de retry opcional - quando nula, nenhum botão é exibido.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppOutlinedButton(label: 'Tentar novamente', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
