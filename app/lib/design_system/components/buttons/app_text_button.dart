import 'package:flutter/material.dart';

/// Botão de texto do BORAH — sem preenchimento nem borda, para ações
/// terciárias/links (ex.: "Esqueci minha senha", "Excluir" destrutivo
/// em `review_detail_page.dart`). Consome exclusivamente
/// `Theme.of(context)` (via `TextButtonThemeData`, já configurado em
/// `core/theme/app_theme.dart`) — nenhuma cor é declarada aqui.
///
/// [isDestructive] tinge o texto com `colorScheme.error` — usar para
/// ações irreversíveis (excluir, sair, remover).
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    if (!isDestructive) {
      return TextButton(onPressed: onPressed, child: Text(label));
    }

    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: scheme.error),
      child: Text(label),
    );
  }
}
