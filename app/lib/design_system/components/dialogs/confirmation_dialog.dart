import 'package:flutter/material.dart';

import '../buttons/app_text_button.dart';

/// Diálogo de confirmação do BORAH.
///
/// Achado real do levantamento do UI-02: nenhuma confirmação existe
/// hoje para ações destrutivas — excluir avaliação
/// (`review_detail_page.dart`) e excluir comentário
/// (`comments_page.dart`) disparam direto, sem nenhum passo
/// intermediário. Este componente fica pronto para preencher essa
/// lacuna; nenhuma tela é alterada para usá-lo nesta rodada.
///
/// Uso: `final confirmed = await ConfirmationDialog.show(context, ...)`.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  /// `true` tinge o botão de confirmação com `colorScheme.error`.
  final bool isDestructive;

  /// Exibe o diálogo e retorna `true` se confirmado, `false` caso
  /// contrário (cancelado ou fechado sem escolha).
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppTextButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppTextButton(
          label: confirmLabel,
          isDestructive: isDestructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
