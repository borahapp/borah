import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_password_field.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/tokens/app_gradients.dart';
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
                height: 48,
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
