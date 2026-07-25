import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/components/buttons/app_text_button.dart';
import '../../design_system/components/dialogs/app_dialog.dart';
import '../../design_system/components/inputs/app_text_field.dart';
import 'feedback_providers.dart';

const _maxMessageLength = 500;

/// Diálogo de envio de feedback (RC-03E) — infraestrutura mínima
/// exigida: campo de texto, contador de caracteres, botão Enviar,
/// estados de carregando/sucesso/erro. Nenhuma listagem/painel
/// administrativo é implementado aqui (fora do escopo desta rodada).
///
/// Vive em `lib/core/feedback/` (não em `design_system/`) porque depende
/// de [FeedbackController] (Riverpod) — mas por dentro reaproveita só
/// componentes do Design System (`AppDialog`/`AppTextField`/
/// `AppTextButton`), sem nenhum `Material`/`TextFormField` cru.
///
/// [userId] é fornecido por quem chama (ex. `SettingsPage`, lendo
/// `currentUserIdProvider`) — `core/` nunca importa `features/`
/// diretamente (ver RC-03D/RC-03E §Camadas), então esta tela não busca o
/// usuário autenticado sozinha.
class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key, required this.userId, this.screenContext});

  final String userId;
  final String? screenContext;

  static Future<void> show(
    BuildContext context, {
    required String userId,
    String? screenContext,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          FeedbackDialog(userId: userId, screenContext: screenContext),
    );
  }

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sempre começa limpo — nunca reaproveita um estado de
    // sucesso/erro deixado por um envio anterior no mesmo app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(feedbackControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    await ref
        .read(feedbackControllerProvider.notifier)
        .submit(
          userId: widget.userId,
          message: message,
          screenContext: widget.screenContext,
        );

    if (!mounted) return;
    final status = ref.read(feedbackControllerProvider);
    if (status is FeedbackSubmitSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback enviado. Obrigado!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(feedbackControllerProvider);
    final isSubmitting = status is FeedbackSubmitting;

    return AppDialog(
      title: 'Enviar feedback',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _controller,
            label: 'Sua mensagem',
            maxLines: 4,
            maxLength: _maxMessageLength,
          ),
          if (status is FeedbackSubmitError) ...[
            const SizedBox(height: 8),
            Text(
              status.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        AppTextButton(
          label: 'Cancelar',
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        if (isSubmitting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          AppTextButton(label: 'Enviar', onPressed: _submit),
      ],
    );
  }
}
