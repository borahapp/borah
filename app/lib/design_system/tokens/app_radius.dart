import 'package:flutter/material.dart';

/// Border Radius Tokens — UI-01 §7 define apenas as categorias
/// (XS/SM/MD/LG/XL/Pill), sem valores. Escala abaixo derivada pelo
/// implementador (FASE 7A), refletindo a personalidade da marca
/// ("divertida, sem ser infantil" - cantos generosamente arredondados,
/// nunca retos, mas sem exagero que pareça infantil).
abstract final class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;

  /// Totalmente arredondado (chips, badges, botões pill).
  static const pill = 999.0;

  static const radiusXs = BorderRadius.all(Radius.circular(xs));
  static const radiusSm = BorderRadius.all(Radius.circular(sm));
  static const radiusMd = BorderRadius.all(Radius.circular(md));
  static const radiusLg = BorderRadius.all(Radius.circular(lg));
  static const radiusXl = BorderRadius.all(Radius.circular(xl));
  static const radiusPill = BorderRadius.all(Radius.circular(pill));
}
