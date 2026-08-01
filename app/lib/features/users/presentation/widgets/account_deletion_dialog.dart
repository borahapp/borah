import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/dialogs/app_dialog.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/inputs/app_password_field.dart';
import '../../application/account_deletion_controller.dart';
import '../states/account_deletion_status.dart';

/// Diálogo de exclusão de conta (RC-04C — LGPD/RN-003). Dois estágios,
/// nesta ordem (RC-04C §Exclusão de Conta):
/// 1. Confirmação explícita — aviso de que a ação é permanente.
/// 2. Reautenticação — confirmação de senha, antes de qualquer chamada.
///
/// [email]/[avatarPath] são fornecidos por quem chama (a tela lê
/// `authControllerProvider`/o perfil atual) — mesma disciplina de
/// `FeedbackDialog` (RC-03E): o diálogo nunca resolve a sessão sozinho.
class AccountDeletionDialog extends ConsumerStatefulWidget {
  const AccountDeletionDialog({
    super.key,
    required this.email,
    this.avatarPath,
  });

  final String email;
  final String? avatarPath;

  static Future<void> show(
    BuildContext context, {
    required String email,
    String? avatarPath,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          AccountDeletionDialog(email: email, avatarPath: avatarPath),
    );
  }

  @override
  ConsumerState<AccountDeletionDialog> createState() =>
      _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends ConsumerState<AccountDeletionDialog> {
  final _passwordController = TextEditingController();
  bool _showPasswordStep = false;

  @override
  void initState() {
    super.initState();
    // Sempre começa limpo — nunca reaproveita um estado de erro deixado
    // por uma tentativa anterior no mesmo app (mesma disciplina de
    // `FeedbackDialog`, RC-03E).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(accountDeletionControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    ref
        .read(accountDeletionControllerProvider.notifier)
        .deleteAccount(
          email: widget.email,
          password: password,
          avatarPath: widget.avatarPath,
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(accountDeletionControllerProvider);
    final isDeleting = status is AccountDeletionInProgress;

    ref.listen<AccountDeletionStatus>(accountDeletionControllerProvider, (
      _,
      next,
    ) {
      if (next is AccountDeletionSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sua conta foi excluída.')),
        );
      }
    });

    if (!_showPasswordStep) {
      return AppDialog(
        title: 'Excluir conta',
        content: const Text(
          'Esta ação é permanente. Todos os seus dados serão removidos. '
          'Esta ação não poderá ser desfeita.',
        ),
        actions: [
          AppTextButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppTextButton(
            label: 'Continuar',
            isDestructive: true,
            onPressed: () => setState(() => _showPasswordStep = true),
          ),
        ],
      );
    }

    return AppDialog(
      title: 'Confirme sua senha',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Por segurança, digite sua senha para confirmar a exclusão.',
          ),
          const SizedBox(height: 12),
          AppPasswordField(controller: _passwordController, label: 'Senha'),
          if (status is AccountDeletionReauthenticationError) ...[
            const SizedBox(height: 8),
            Text(
              status.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (status is AccountDeletionError) ...[
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
          onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
        ),
        if (isDeleting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: LoadingIndicator(size: 20),
          )
        else
          AppTextButton(
            label: 'Excluir minha conta',
            isDestructive: true,
            onPressed: _submit,
          ),
      ],
    );
  }
}
