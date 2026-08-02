import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Centraliza o `ThemeData` (UI-03/UI-04: "nunca utilizar valores
/// diretamente nos widgets, apenas tokens/ThemeData").
///
/// Design System oficial do BORAH (UI-01, FASE 7A) — arquitetura em
/// camadas, nunca o inverso:
/// ```text
/// Brand Tokens (design_system/brand/)     - identidade pura da marca
///        ↓
/// Material Tokens (tokens/, typography/)  - traduz Brand Tokens para
///        ↓                                  algo que ColorScheme/
///        ↓                                  TextTheme consegue usar
/// ThemeData (este arquivo)
///        ↓
/// Widgets (Theme.of(context) - nunca importam Brand Tokens direto)
/// ```
///
/// [BrandColors] é importado aqui diretamente só onde a marca exige um
/// valor **sempre exato**, independente do tema (o preenchimento do
/// `FilledButton`, que deve ser o Roxo BORAH puro tanto no Light quanto
/// no Dark Theme) - todo o resto do `ColorScheme` vem de [AppColors]
/// (camada Material, já deriva de [BrandColors] internamente).
abstract final class AppTheme {
  static ColorScheme get _lightColorScheme =>
      ColorScheme.fromSeed(
        seedColor: AppColors.roxoBorah,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.roxoBorah,
        onPrimary: AppColors.onRoxo,
        tertiary: AppColors.verdeBorah,
        onTertiary: AppColors.onVerde,
        error: AppColors.error,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.pretoUva,
      );

  /// Dark Theme usa [AppColors.roxoBorahLight] (não o Roxo BORAH puro)
  /// como `primary` - ver doc do token: Roxo BORAH puro como cor de
  /// texto/ícone sobre fundo escuro fica abaixo do contraste mínimo do
  /// WCAG AA. Botões preenchidos (`FilledButtonThemeData` abaixo)
  /// continuam usando o Roxo BORAH exato ([BrandColors.purple]) em
  /// ambos os temas.
  static ColorScheme get _darkColorScheme =>
      ColorScheme.fromSeed(
        seedColor: AppColors.roxoBorah,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.roxoBorahLight,
        onPrimary: AppColors.pretoUva,
        tertiary: AppColors.verdeBorah,
        onTertiary: AppColors.onVerde,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.neutral800,
        onSurface: Colors.white,
      );

  /// Preenchimento sempre [BrandColors.purple] exato — decisão de
  /// marca, não de tema (independe de `ColorScheme.primary`, que no
  /// Dark Theme usa a tinta clara [AppColors.roxoBorahLight] por
  /// motivo de contraste de texto, não de preenchimento de botão).
  static FilledButtonThemeData get _filledButtonTheme => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: BrandColors.purple,
      foregroundColor: AppColors.onRoxo,
      minimumSize: const Size.fromHeight(48),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    );
  }

  static CardThemeData get _cardTheme => CardThemeData(
    elevation: AppElevation.level1,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
    margin: EdgeInsets.zero,
  );

  /// UI-03B (tema global). Propriedades customizadas e por quê:
  /// - `centerTitle: false` — decisão explícita (era o default implícito
  ///   do Material no Android, agora documentado), consistente com os
  ///   wireframes (título sempre alinhado à esquerda).
  /// - `scrolledUnderElevation: AppElevation.level1` — troca o valor
  ///   não-documentado do Material 3 (3.0) pela escala de elevação do
  ///   BORAH, mantendo o mesmo efeito (leve separação ao rolar).
  /// Cor de fundo/primeiro plano não são sobrescritas — já vêm
  /// corretamente de `ColorScheme.surface`/`onSurface` (M3 padrão).
  static AppBarThemeData get _appBarTheme => AppBarThemeData(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: AppElevation.level1,
  );

  /// UI-03B (tema global). Propriedades customizadas e por quê:
  /// - `shape`/`AppRadius.radiusXl` (24) — o default do Material 3 é
  ///   28, fora da escala de raios do BORAH (máximo `xl` = 24).
  /// Cor de fundo não é sobrescrita — já vem de `ColorScheme.surface`.
  static DialogThemeData get _dialogTheme => DialogThemeData(
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
  );

  /// UI-03B (tema global). Propriedades customizadas e por quê:
  /// - `shape`/pill (`AppRadius.radiusPill`) — Manual da Marca usa
  ///   formato pílula para selos/etiquetas (mesmo padrão já adotado em
  ///   `ScoreBubble`/`AppBadge`); o default do Material 3 é um
  ///   `StadiumBorder` só quando `selected`, retangular arredondado
  ///   caso contrário — a pílula fixa garante consistência nos dois
  ///   estados.
  /// - `labelStyle`/Manrope — herdado de `AppTypography.textTheme`, meio
  ///   `bodyMedium`/`labelLarge` para não conflitar com o texto normal
  ///   de campo.
  /// Tema nativo do Material `Chip`/`ChipTheme` — nenhum widget do
  /// projeto o usa hoje (`AppBadge` cobre o caso de selo/etiqueta), mas
  /// fica configurado para qualquer `Chip` nativo que venha a aparecer
  /// via widget de terceiros.
  static ChipThemeData _chipTheme(ColorScheme scheme) {
    return ChipThemeData(
      shape: const StadiumBorder(),
      labelStyle: AppTypography.textTheme.labelLarge,
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.tertiary,
      side: BorderSide.none,
    );
  }

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: Colors.white,
    textTheme: AppTypography.textTheme,
    filledButtonTheme: _filledButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputDecorationTheme(_lightColorScheme),
    cardTheme: _cardTheme,
    appBarTheme: _appBarTheme,
    dialogTheme: _dialogTheme,
    chipTheme: _chipTheme(_lightColorScheme),
    extensions: const [AppGradients.brand],
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: AppColors.pretoUva,
    textTheme: AppTypography.textTheme,
    filledButtonTheme: _filledButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputDecorationTheme(_darkColorScheme),
    cardTheme: _cardTheme,
    appBarTheme: _appBarTheme,
    dialogTheme: _dialogTheme,
    chipTheme: _chipTheme(_darkColorScheme),
    extensions: const [AppGradients.brand],
  );
}
