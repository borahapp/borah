import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_password_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/auth_controller.dart';
import '../states/auth_status.dart';

/// Tela "Definir nova senha" (RC-04E), aberta pelo router assim que o
/// `AuthStatus` vira `PasswordRecoveryInProgress` - o usuário chega aqui
/// automaticamente ao abrir o link de recuperação de senha recebido por
/// e-mail (deep link `borah://password-recovery`), nunca por navegação
/// manual.
class NewPasswordPage extends ConsumerStatefulWidget {
  const NewPasswordPage({super.key});

  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .updatePassword(_passwordController.text);
  }

  void _cancel() {
    ref.read(authControllerProvider.notifier).signOut().catchError((_) {
      // Best-effort - `PasswordRecoveryInProgress` sempre tem uma sessão
      // válida (mesmo que temporária), então signOut() não deveria falhar
      // aqui; se falhar mesmo assim, o usuário permanece na tela e pode
      // tentar novamente.
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider);
    final isLoading = status is AuthLoading;

    ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
      if (next is PasswordRecoveryInProgress && previous is AuthLoading) {
        final message = ref
            .read(authControllerProvider.notifier)
            .consumePasswordRecoveryError();
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Definir nova senha'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Escolha uma nova senha para a sua conta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPasswordField(
                  controller: _passwordController,
                  label: 'Nova senha',
                  validator: validatePassword,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPasswordField(
                  controller: _confirmController,
                  label: 'Confirmar nova senha',
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Salvar nova senha',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                AppTextButton(
                  label: 'Cancelar',
                  onPressed: isLoading ? null : _cancel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
