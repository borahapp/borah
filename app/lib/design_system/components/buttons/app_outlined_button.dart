import 'package:flutter/material.dart';

/// Botão com borda do BORAH — sem preenchimento, usado para ações
/// alternativas (ex.: "Ver avaliações", "Alterar foto de capa",
/// achados reais em `restaurant_detail_page.dart`/`review_detail_page.dart`
/// durante o levantamento do UI-02). Consome exclusivamente
/// `Theme.of(context)` (via `OutlinedButtonThemeData`, já configurado
/// em `core/theme/app_theme.dart`) — nenhuma cor/raio é declarado aqui.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Ícone opcional exibido antes do rótulo.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    return SizedBox(
      width: double.infinity,
      child: icon == null || isLoading
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: child,
            ),
    );
  }
}
