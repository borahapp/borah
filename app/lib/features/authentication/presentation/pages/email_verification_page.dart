import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_icon_size.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/auth_controller.dart';
import '../../domain/auth_repository.dart';
import '../states/auth_status.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _isResending = false;

  Future<void> _resend(String email) async {
    setState(() => _isResending = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resendVerificationEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de confirmação reenviado.')),
      );
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider);
    final email = status is EmailVerificationPending ? status.email : null;

    return Scaffold(
      // RC-03 Sprint 2 (RC03_DESIGN_GAP.md §1.2): antes desta rodada, a
      // única saída era o AppTextButton "Voltar para o login" abaixo -
      // achado do UI Audit, "affordance de navegação, não só estética".
      // `leading` é explícito (não a detecção automática do AppBar) -
      // esta tela só é alcançada via `context.go('/email-verification')`
      // (`signup_page.dart`), nunca `push()`, então `Navigator.canPop()`
      // é sempre `false` aqui; sem `leading` explícito, o AppBar padrão
      // simplesmente não mostraria nenhuma seta, silenciosamente.
      appBar: AppTopBar(
        title: 'Confirmação de e-mail',
        leading: AppIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Voltar',
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: AppIconSize.xl,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Confirme seu e-mail para concluir o cadastro. Enviamos um '
                'link de confirmação para o endereço informado.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppOutlinedButton(
                label: 'Reenviar e-mail',
                isLoading: _isResending,
                onPressed: email == null ? null : () => _resend(email),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextButton(
                label: 'Voltar para o login',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
