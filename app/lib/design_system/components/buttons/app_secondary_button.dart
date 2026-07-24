import 'package:flutter/material.dart';

/// Botão secundário do BORAH — preenchido com a cor tonal
/// (`colorScheme.secondaryContainer`), um degrau abaixo do
/// `AppPrimaryButton` (`buttons/app_primary_button.dart`) na
/// hierarquia de ações. Consome exclusivamente `Theme.of(context)`
/// (via `FilledButton.tonal`) — nenhuma cor/raio é declarado aqui.
///
/// Uso recomendado: ação relevante mas não a principal da tela (ex.:
/// "Salvar rascunho" ao lado de um "Publicar" como [AppPrimaryButton]).
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
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
          ? FilledButton.tonal(
              onPressed: isLoading ? null : onPressed,
              child: child,
            )
          : FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: child,
            ),
    );
  }
}
