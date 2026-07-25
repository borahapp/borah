import 'package:flutter/material.dart';

/// Campo de texto do BORAH.
///
/// Migrado de `core/widgets/app_text_field.dart` para cá no UI-03A
/// (Component Migration, prevista desde o UI-02): era o último
/// componente-base fora de `design_system/components/`. `core/widgets/`
/// foi removido depois desta migração.
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
    this.suffixIconTooltip,
    this.onSuffixIconTap,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  /// Número de linhas do campo — `1` (padrão) preserva o comportamento
  /// anterior ao RC-03E. Um valor maior que `1` habilita texto
  /// multilinha (ex.: campo de mensagem do `FeedbackDialog`).
  final int maxLines;

  /// Limite de caracteres exibido como contador nativo do
  /// `TextFormField` (RC-03E) — `null` (padrão) mantém o comportamento
  /// anterior, sem contador.
  final int? maxLength;

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

  /// Rótulo semântico do botão do [suffixIcon] — obrigatório sempre que
  /// [suffixIcon] é informado (mesma exigência de acessibilidade do
  /// `AppIconButton`).
  final String? suffixIconTooltip;
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
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                icon: Icon(suffixIcon),
                tooltip: suffixIconTooltip,
                onPressed: onSuffixIconTap,
              ),
      ),
    );
  }
}
