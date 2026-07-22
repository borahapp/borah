/// Barrel file do Design System oficial do BORAH (UI-01, FASE 7A).
/// Importar este arquivo dá acesso a todos os tokens sem precisar
/// conhecer a estrutura interna de `design_system/`.
///
/// Arquitetura em camadas (nunca o inverso):
/// ```text
/// Brand Tokens (brand/)          - identidade pura da marca
///        ↓
/// Material Tokens (tokens/, typography/) - traduz Brand Tokens para ThemeData
///        ↓
/// ThemeData (core/theme/app_theme.dart)
///        ↓
/// Widgets
/// ```
library;

export 'brand/brand_colors.dart';
export 'brand/brand_gradients.dart';
export 'brand/brand_typography.dart';
export 'tokens/app_colors.dart';
export 'tokens/app_elevation.dart';
export 'tokens/app_gradients.dart';
export 'tokens/app_radius.dart';
export 'tokens/app_shadows.dart';
export 'tokens/app_spacing.dart';
export 'typography/app_typography.dart';
