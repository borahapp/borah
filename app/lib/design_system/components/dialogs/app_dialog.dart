import 'package:flutter/material.dart';

/// Diálogo genérico do BORAH — envolve `AlertDialog`. Estilo (raio,
/// cor de fundo) vem de `Theme.of(context)` (`DialogTheme` implícito
/// do Material 3) — nenhum valor é declarado aqui.
///
/// Base para diálogos especializados (ex.: [ConfirmationDialog]).
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, this.content, this.actions});

  final String title;
  final Widget? content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(title: Text(title), content: content, actions: actions);
  }
}
