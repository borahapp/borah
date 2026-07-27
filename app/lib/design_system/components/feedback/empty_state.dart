import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_spacing.dart';

/// Estado vazio do BORAH.
///
/// Achado real do levantamento do UI-02: 13 mensagens de estado vazio
/// diferentes (ex.: "Nenhuma avaliação ainda.", "Você ainda não tem
/// favoritos.") eram um `Center(child: Text('...'))` isolado, repetido
/// em cada arquivo, sem ilustração nem ação — resolvido na RC-02
/// (componente único) e, nesta rodada (IV-06), com a expressão oficial
/// do símbolo BORAH sorrindo em vez de um ícone Material genérico.
/// Nenhuma das 14 telas que usam este componente customiza o ícone
/// antigo (confirmado por busca antes da mudança), então a troca se
/// aplica de forma consistente em todas de uma vez.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.action});

  final String message;

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
            SvgPicture.asset(
              'assets/borah/ui/expressions/symbol_smiling.svg',
              width: 64,
              height: 64,
              semanticsLabel: 'Símbolo do BORAH sorrindo',
            ),
            const SizedBox(height: AppSpacing.md),
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
