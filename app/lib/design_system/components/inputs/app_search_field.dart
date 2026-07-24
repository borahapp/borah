import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// Campo de busca do BORAH — composição sobre `AppTextField`
/// (`inputs/app_text_field.dart`), não uma reimplementação.
///
/// Achado real do levantamento do UI-02: `favorites_page.dart` e
/// `restaurants_search_page.dart` já usam `AppTextField` como busca,
/// mas sem ícone de lupa nem botão de limpar — cada tela reimplementa o
/// mesmo campo do zero. Este componente formaliza esse padrão.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.label,
    this.onSubmit,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final void Function(String?)? onSubmit;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AppTextField(
          controller: controller,
          label: label,
          keyboardType: TextInputType.text,
          onSubmit: onSubmit,
          prefixIcon: Icons.search,
          suffixIcon: controller.text.isEmpty ? null : Icons.clear,
          suffixIconTooltip: controller.text.isEmpty ? null : 'Limpar busca',
          onSuffixIconTap: controller.text.isEmpty
              ? null
              : () {
                  controller.clear();
                  onChanged?.call('');
                },
          onChanged: onChanged,
        );
      },
    );
  }
}
