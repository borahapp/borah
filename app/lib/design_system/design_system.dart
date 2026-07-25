/// Barrel file do Design System oficial do BORAH (UI-01, FASE 7A;
/// componentes adicionados no UI-02). Importar este arquivo dá acesso
/// a todos os tokens e componentes sem precisar conhecer a estrutura
/// interna de `design_system/`.
///
/// Arquitetura em camadas (nunca o inverso):
/// ```text
/// Brand Tokens (brand/)          - identidade pura da marca
///        ↓
/// Material Tokens (tokens/, typography/) - traduz Brand Tokens para ThemeData
///        ↓
/// ThemeData (core/theme/app_theme.dart)
///        ↓
/// Components (components/)       - consomem Theme.of(context) + tokens
///        ↓                         de Material (nunca Brand Tokens direto)
/// Telas/Widgets de feature
/// ```
///
/// **Telas/widgets de feature:** prefira importar apenas
/// `design_system/components/components.dart` em vez deste barrel
/// completo — evita expor `brand/` (identidade pura da marca, nunca
/// deve ser acessada fora de `tokens/`/`typography/`/`app_theme.dart`)
/// a código que não deveria depender dela.
library;

export 'animations/app_motion.dart';
export 'brand/brand_colors.dart';
export 'brand/brand_gradients.dart';
export 'brand/brand_typography.dart';
export 'components/components.dart';
export 'tokens/app_colors.dart';
export 'tokens/app_elevation.dart';
export 'tokens/app_gradients.dart';
export 'tokens/app_radius.dart';
export 'tokens/app_shadows.dart';
export 'tokens/app_spacing.dart';
export 'typography/app_typography.dart';
