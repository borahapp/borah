import 'package:flutter/material.dart';

// Gradient values derived from the official brand artwork.
// The Brand Manual does not specify official HEX values.
//
// A arte da página 6 do Manual Oficial da Marca BORAH (v1.0, jul/2026)
// mostra dois gradientes ("Gradientes Oficiais" no manual, referindo-se
// à *arte*, não a valores hex), mas o PDF não lista nenhum hex em
// texto para eles. Os valores abaixo foram obtidos por amostragem
// direta de pixel dessa arte (não estimados visualmente, não
// inventados) — ver relatório da FASE 7A/UI-01 para a metodologia.
abstract final class BrandGradients {
  /// Amostrado da arte oficial: `#6B2FFF` → `#4915D0`.
  static const purple = LinearGradient(
    colors: [Color(0xFF6B2FFF), Color(0xFF4915D0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Amostrado da arte oficial: `#C2FF02` → `#97D702`.
  static const green = LinearGradient(
    colors: [Color(0xFFC2FF02), Color(0xFF97D702)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
