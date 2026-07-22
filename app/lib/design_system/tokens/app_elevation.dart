/// Elevation Tokens — UI-01 §8. Valores numéricos (dp) para widgets que
/// usam a propriedade `elevation` nativa do Material (`Card`,
/// `ElevatedButton`, `AppBar`, `BottomSheet`) — para `Container`/`Box`
/// customizados que precisam de `BoxShadow` explícito, ver
/// [AppShadows] (mesmos 5 níveis, unidades diferentes).
abstract final class AppElevation {
  static const level0 = 0.0;
  static const level1 = 1.0;
  static const level2 = 3.0;
  static const level3 = 6.0;
  static const level4 = 12.0;
}
