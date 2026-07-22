import 'package:flutter/material.dart';

/// Botão de ação flutuante do BORAH.
///
/// Usa `colorScheme.tertiary`/`onTertiary` (Verde BORAH/Preto Uva) em
/// vez do `primary` padrão do Material — decisão de marca: "Verde [...]
/// destaca ações, notas e momentos importantes" (Manual §05), e um FAB
/// é, por definição, a ação mais importante e singular da tela. Cores
/// vêm de `Theme.of(context).colorScheme`, nunca de `BrandColors`
/// diretamente.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Quando informado, renderiza um FAB estendido (ícone + texto) em
  /// vez do FAB circular padrão.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
        icon: Icon(icon),
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: scheme.tertiary,
      foregroundColor: scheme.onTertiary,
      child: Icon(icon),
    );
  }
}
