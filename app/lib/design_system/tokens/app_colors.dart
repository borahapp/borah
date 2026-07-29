import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

/// Color Tokens — camada Material. Traduz os [BrandColors] (identidade
/// pura da marca) para algo que o `ColorScheme`/`ThemeData` consegue
/// consumir: escala neutra, cores semânticas e pares de contraste
/// (`on-*`). Nada disso existe no Manual da Marca (que só define as 3
/// cores em [BrandColors]) — foi derivado pelo implementador (FASE
/// 7A/UI-01), ancorado em [BrandColors.black] como `neutral900` e
/// validado por contraste WCAG (ver comentário de cada valor `on-*`).
///
/// Fluxo de dependência (nunca o inverso):
/// ```text
/// BrandColors → AppColors/ColorScheme (aqui) → ThemeData → Widgets
/// ```
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Reexporta os Brand Tokens (nunca redefine o hex - sempre aponta
  // para a fonte única em BrandColors)
  // ---------------------------------------------------------------------

  static const roxoBorah = BrandColors.purple;
  static const verdeBorah = BrandColors.green;
  static const pretoUva = BrandColors.black;

  /// Tinta lavanda clara de [roxoBorah] (mistura de 35% com branco) —
  /// **não é uma cor da marca** ([BrandColors] não a define. Existe
  /// apenas porque o Roxo BORAH puro, usado como cor de TEXTO/ícone
  /// sobre fundos escuros (Preto Uva/Neutral 800), fica abaixo do
  /// contraste mínimo do WCAG AA (2.58–3.11:1, ver relatório da FASE
  /// 7A). Usada somente como `ColorScheme.primary` no Dark Theme para
  /// papéis incidentais de texto/ícone; botões preenchidos continuam
  /// usando [BrandColors.purple] exato em ambos os temas
  /// (`FilledButtonThemeData`, não depende do `ColorScheme`).
  static const roxoBorahLight = Color(0xFF9477FF);

  // ---------------------------------------------------------------------
  // Escala neutra (derivada, ancorada em BrandColors.black = Neutral 900)
  // ---------------------------------------------------------------------

  static const neutral50 = Color(0xFFF7F6FA);
  static const neutral100 = Color(0xFFEFEDF5);
  static const neutral200 = Color(0xFFDEDAE8);
  static const neutral300 = Color(0xFFC4BED6);
  static const neutral400 = Color(0xFF9C93B3);
  static const neutral500 = Color(0xFF756B8F);
  static const neutral600 = Color(0xFF554C6E);
  static const neutral700 = Color(0xFF3A3252);
  static const neutral800 = Color(0xFF211A38);
  static const neutral900 = BrandColors.black;

  // ---------------------------------------------------------------------
  // Semânticas (derivadas - manual não define; Success reaproveita o
  // Verde BORAH, coerente com "Verde [...] destaca momentos importantes")
  // ---------------------------------------------------------------------

  static const success = BrandColors.green;
  static const warning = Color(0xFFFFB020);
  static const error = Color(0xFFFF3B5C);
  static const info = roxoBorahLight;

  // ---------------------------------------------------------------------
  // Pares "on-*" (texto/ícone sobre cor sólida) — validados por contraste
  // WCAG (fórmula de luminância relativa, sRGB)
  // ---------------------------------------------------------------------

  /// Sobre [BrandColors.purple]: branco = 6.40:1 (AA para texto normal).
  static const onRoxo = Color(0xFFFFFFFF);

  /// Sobre [BrandColors.green]: Preto Uva = 16.50:1 — também é o que o
  /// próprio material do manual usa (confirmado por amostragem de
  /// pixel da página 6, não apenas suposição).
  static const onVerde = BrandColors.black;

  /// Sobre [BrandColors.black]: branco = 19.91:1.
  static const onPretoUva = Color(0xFFFFFFFF);
}
