import 'package:flutter/material.dart';

/// Centralizes ThemeData (UI-03/UI-04: "nunca utilizar valores diretamente
/// nos widgets, apenas tokens/ThemeData").
///
/// Tipografia: segue exatamente a escala, pesos e faixas de altura de linha
/// definidos em UI-04_TYPOGRAPHY.md (fonte Inter, hierarquia Material 3).
/// Pesos por estilo e o valor exato de altura de linha (dentro da faixa
/// documentada) seguem a convenção padrão do Material Design 3, citada
/// como referência pelo próprio UI-04 (§4).
///
/// Cores: UI-02/UI-03 definem apenas categorias (Primary/Secondary/Accent,
/// Neutral 50-900, etc.), sem nenhum valor de cor (hex/RGB) real. Como não
/// há valor especificado, o ColorScheme usa o padrão do Material 3 até que
/// a FASE 3 defina a paleta oficial.
abstract final class AppTheme {
  static const _fontFamily = 'Inter';
  static const _fontFamilyFallback = ['Roboto', 'SF Pro Text', 'sans-serif'];

  static const _headingHeight = 1.15; // UI-04 §7: títulos 110%-120%
  static const _bodyHeight = 1.5; // UI-04 §7: corpo 140%-160%
  static const _labelHeight = 1.3; // UI-04 §7: labels 120%-140%

  static final TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: _headingHeight,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: _headingHeight,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: _headingHeight,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: _headingHeight,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: _headingHeight,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: _headingHeight,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      height: _headingHeight,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: _headingHeight,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: _headingHeight,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: _bodyHeight,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: _bodyHeight,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: _bodyHeight,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: _labelHeight,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: _labelHeight,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: _labelHeight,
    ),
  ).apply(fontFamily: _fontFamily, fontFamilyFallback: _fontFamilyFallback);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: _textTheme,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: _textTheme,
  );
}
