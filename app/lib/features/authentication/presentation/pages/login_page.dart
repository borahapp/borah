import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_password_field.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/tokens/app_gradients.dart';
import '../../../../design_system/tokens/app_icon_size.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/auth_controller.dart';
import '../states/auth_status.dart';
import '../widgets/auth_error_listener.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // RC-03 Sprint 2: flag local, não `AuthStatus` compartilhado - mesmo
  // padrão já usado por `_isResending` em `email_verification_page.dart`.
  // `AuthStatus.AuthLoading` é único para todos os provedores; se o
  // spinner do Google também reagisse a ele, tocar em "Entrar" faria o
  // botão do Google (nunca tocado) mostrar spinner também - confirmado
  // como regressão real ao rodar a suíte existente, não só uma hipótese.
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _submitGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider);
    final isLoading = status is AuthLoading;

    listenForAuthErrors(ref, context);

    final gradients = AppGradients.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + AppSpacing.xxl,
              bottom: AppSpacing.xxl,
            ),
            decoration: BoxDecoration(gradient: gradients.purple),
            // IV-04: logo oficial em vez do texto "BORAH" estilizado. A
            // versão colorida (dark/light) usa o mesmo tom de roxo deste
            // gradiente e perderia contraste aqui - a versão branca
            // monocromática ("aplicação branca de uma cor", por
            // instrução do material oficial) é a que preserva contraste
            // sobre um fundo já roxo, diferente de um fundo escuro
            // neutro. `BoxFit.contain` preserva a proporção original.
            child: Center(
              child: SizedBox(
                height: AppIconSize.xl,
                child: SvgPicture.asset(
                  'assets/borah/logos/borah_logo_white.svg',
                  semanticsLabel: 'BORAH',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _emailController,
                        label: 'E-mail',
                        keyboardType: TextInputType.emailAddress,
                        validator: validateEmail,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppPasswordField(
                        controller: _passwordController,
                        label: 'Senha',
                        validator: (value) =>
                            validateRequired(value, 'sua senha'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppPrimaryButton(
                        label: 'Entrar',
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('ou', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.lg),
                      // RC-03 Sprint 2 (F02): backend já pronto desde a
                      // RC-02D (`AuthController.signInWithGoogle()`) - só
                      // faltava o botão. Spinner controlado por
                      // `_isGoogleLoading` (local), não pelo `isLoading`
                      // compartilhado do e-mail/senha - ver comentário no
                      // campo acima.
                      AppOutlinedButton(
                        label: 'Continuar com Google',
                        isLoading: _isGoogleLoading,
                        onPressed: _submitGoogle,
                      ),
                      AppTextButton(
                        label: 'Esqueci minha senha',
                        onPressed: () => context.push('/password-reset'),
                      ),
                      AppTextButton(
                        label: 'Criar conta',
                        onPressed: () => context.push('/signup'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
