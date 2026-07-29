import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_spacing.dart';
import '../buttons/app_outlined_button.dart';

/// Estado de erro do BORAH (RC-02, Quick Win).
///
/// Achado real da RC-01: o padrão `Center(child: Text(message))` sem
/// nenhuma ação de retry se repete em praticamente toda tela do app.
/// Este componente centraliza a estrutura visual - a mensagem em si
/// continua sendo responsabilidade de cada tela. Desde a IV-06, usa a
/// expressão oficial do símbolo BORAH surpreso em vez do ícone Material
/// genérico (`Icons.error_outline`) - nenhum dos ~19 pontos de uso
/// customiza o ícone antigo (confirmado por busca antes da mudança),
/// então a troca se aplica de forma consistente em todos de uma vez.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;

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
            SvgPicture.asset(
              'assets/borah/ui/expressions/symbol_surprised.svg',
              width: 64,
              height: 64,
              semanticsLabel: 'Símbolo do BORAH surpreso',
            ),
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
