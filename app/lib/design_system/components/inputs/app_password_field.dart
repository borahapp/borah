import 'package:flutter/material.dart';

import '../../../core/widgets/app_text_field.dart';

/// Campo de senha do BORAH — composição sobre `AppTextField`
/// (`core/widgets/app_text_field.dart`), adicionando o alternador de
/// visibilidade que faltava.
///
/// Achado real do levantamento do UI-02: `login_page.dart` e a tela de
/// cadastro usam `AppTextField(obscureText: true)` sem nenhum botão
/// para revelar a senha digitada.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onSubmit,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final void Function(String?)? onSubmit;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      obscureText: _obscured,
      validator: widget.validator,
      onSubmit: widget.onSubmit,
      suffixIcon: _obscured ? Icons.visibility : Icons.visibility_off,
      onSuffixIconTap: () => setState(() => _obscured = !_obscured),
    );
  }
}
