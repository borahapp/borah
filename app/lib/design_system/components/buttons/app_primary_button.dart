import 'package:flutter/material.dart';

/// Botão primário do BORAH — ação principal de cada tela.
///
/// Migrado de `core/widgets/app_primary_button.dart` para cá no
/// UI-03A (Component Migration, prevista desde o UI-02): era o último
/// componente-base fora de `design_system/components/`. `core/widgets/`
/// foi removido depois desta migração.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
