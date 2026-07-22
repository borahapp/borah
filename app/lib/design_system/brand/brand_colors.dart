import 'package:flutter/material.dart';

/// Brand Tokens — Identidade da Marca. Camada mais baixa do Design
/// System: nunca deriva de nada, nunca é derivada por conveniência de
/// widget. Fonte única: Manual Oficial da Marca BORAH (v1.0, jul/2026),
/// §05 "Cores".
///
/// Apenas as 3 cores oficiais da marca vivem aqui — nenhuma escala
/// neutra, semântica ou par de contraste (`on-*`). Essa tradução para
/// Material Design é responsabilidade da camada de tokens
/// (`design_system/tokens/app_colors.dart`), que **consome** estas
/// constantes para construir o `ColorScheme`/`ThemeData`.
///
/// Fluxo de dependência (nunca o inverso):
/// ```text
/// BrandColors → AppColors/ColorScheme (Material) → ThemeData → Widgets
/// ```
abstract final class BrandColors {
  /// Roxo BORAH — #5B2EFF. "Roxo dá personalidade [...] Roxo domina."
  static const purple = Color(0xFF5B2EFF);

  /// Verde BORAH — #B8FF3B. "Verde cria energia e ação [...] destaca
  /// ações, notas e momentos importantes."
  static const green = Color(0xFFB8FF3B);

  /// Preto Uva — #0B0714. Cor de tinta/fundo escuro oficial.
  static const black = Color(0xFF0B0714);
}
