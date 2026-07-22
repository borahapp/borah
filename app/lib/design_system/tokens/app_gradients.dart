import 'package:flutter/material.dart';

import '../brand/brand_gradients.dart';

/// Camada Material: expõe os [BrandGradients] via `ThemeData.extensions`,
/// para que widgets consumam gradientes através de `Theme.of(context)`
/// (como qualquer outro token) em vez de importar `BrandGradients`
/// diretamente — mesma regra de dependência de [AppColors]/`ColorScheme`:
/// ```text
/// BrandGradients → AppGradients (ThemeExtension) → ThemeData → Widgets
/// ```
@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  const AppGradients({required this.purple, required this.green});

  /// Instância única, construída a partir dos Brand Tokens - nenhum
  /// widget deve construir [AppGradients] diretamente.
  static const brand = AppGradients(
    purple: BrandGradients.purple,
    green: BrandGradients.green,
  );

  final LinearGradient purple;
  final LinearGradient green;

  @override
  AppGradients copyWith({LinearGradient? purple, LinearGradient? green}) {
    return AppGradients(
      purple: purple ?? this.purple,
      green: green ?? this.green,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      purple: LinearGradient.lerp(purple, other.purple, t)!,
      green: LinearGradient.lerp(green, other.green, t)!,
    );
  }
}
