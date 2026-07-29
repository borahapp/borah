import 'package:flutter/material.dart';

import '../brand/brand_typography.dart';

/// Typography Tokens — camada Material. Traduz os [BrandTypography]
/// (só os nomes das famílias oficiais) para a hierarquia do Material 3
/// que o `ThemeData.textTheme` consegue consumir — tamanhos, pesos e
/// alturas de linha, nenhum dos quais o Manual da Marca define (UI-01
/// §4, UI-04).
///
/// Fluxo de dependência (nunca o inverso):
/// ```text
/// BrandTypography → AppTypography (aqui) → ThemeData → Widgets
/// ```
///
/// - [BrandTypography.headingFontFamily] (Fredoka, Semibold 600 / Bold
///   700) — Display/Headline/Title.
/// - [BrandTypography.bodyFontFamily] (Manrope, Regular 400 / Semibold
///   600 / Bold 700) — Body/Label.
///
/// Escala de tamanhos e faixas de altura de linha mantidas exatamente
/// como já documentado em UI-04 §5/§7 (nenhuma mudança de tamanho
/// nesta rodada - apenas fonte e peso, para alinhar ao manual oficial).
abstract final class AppTypography {
  static const _headingHeight = 1.15; // UI-04 §7: títulos 110%-120%
  static const _bodyHeight = 1.5; // UI-04 §7: corpo 140%-160%
  static const _labelHeight = 1.3; // UI-04 §7: labels 120%-140%

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w700,
      height: _headingHeight,
    ),
    displayMedium: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 45,
      fontWeight: FontWeight.w700,
      height: _headingHeight,
    ),
    displaySmall: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: _headingHeight,
    ),
    headlineLarge: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: _headingHeight,
    ),
    headlineMedium: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: _headingHeight,
    ),
    headlineSmall: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: _headingHeight,
    ),
    titleLarge: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: _headingHeight,
    ),
    titleMedium: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: _headingHeight,
    ),
    titleSmall: TextStyle(
      fontFamily: BrandTypography.headingFontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: _headingHeight,
    ),
    bodyLarge: TextStyle(
      fontFamily: BrandTypography.bodyFontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: _bodyHeight,
    ),
    bodyMedium: TextStyle(
      fontFamily: BrandTypography.bodyFontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: _bodyHeight,
    ),
    bodySmall: TextStyle(
      fontFamily: BrandTypography.bodyFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: _bodyHeight,
    ),
    labelLarge: TextStyle(
      fontFamily: BrandTypography.bodyFontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: _labelHeight,
    ),
    labelMedium: TextStyle(
      fontFamily: BrandTypography.bodyFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: _labelHeight,
    ),
    labelSmall: TextStyle(
      fontFamily: BrandTypography.bodyFontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: _labelHeight,
    ),
  );
}
