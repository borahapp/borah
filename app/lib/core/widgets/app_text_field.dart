import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSubmit,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  /// Chamado quando o usuário confirma o campo (Enter/"concluído" no
  /// teclado) — usado por campos de busca/filtro (DV-03).
  final void Function(String?)? onSubmit;

  /// Chamado a cada alteração do texto (UI-02: `AppSearchField`,
  /// `AppPasswordField`). `null` por padrão — mesmo comportamento de
  /// antes do UI-02 para quem não usa este parâmetro.
  final void Function(String)? onChanged;

  /// Ícone opcional antes do campo (UI-02: `AppSearchField`).
  final IconData? prefixIcon;

  /// Ícone opcional depois do campo, tocável via [onSuffixIconTap]
  /// (UI-02: `AppSearchField` "limpar", `AppPasswordField`
  /// mostrar/ocultar senha).
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmit,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(icon: Icon(suffixIcon), onPressed: onSuffixIconTap),
      ),
    );
  }
}
