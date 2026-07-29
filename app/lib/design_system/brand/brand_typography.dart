/// Brand Tokens — Identidade tipográfica da marca. Manual Oficial da
/// Marca BORAH (v1.0, jul/2026), §06 "Tipografia".
///
/// Apenas os NOMES das famílias oficiais vivem aqui. A tradução para a
/// hierarquia do Material 3 (tamanhos, pesos, alturas de linha) é
/// responsabilidade da camada de tokens
/// (`design_system/typography/app_typography.dart`), que **consome**
/// estas constantes.
abstract final class BrandTypography {
  /// Fredoka — títulos e chamadas. Pesos recomendados: Semibold 600 e
  /// Bold 700.
  static const headingFontFamily = 'Fredoka';

  /// Manrope — textos, interface e dados. Pesos recomendados: Regular
  /// 400, Semibold 600 e Bold 700.
  static const bodyFontFamily = 'Manrope';
}
