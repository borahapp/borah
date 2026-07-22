import 'package:flutter/material.dart';

/// Elevation/Shadow Tokens — UI-01 §8 define apenas os níveis (Level
/// 0-4), sem valores. Sombras abaixo são neutras e discretas por
/// decisão deliberada: o Manual da Marca (§08 "Cuidados") proíbe
/// "adicionar efeitos" (contornos, sombras e brilho fora do sistema) -
/// nenhuma sombra colorida/glow de marca foi criada, apenas elevação
/// funcional padrão (preto com opacidade baixa), a mesma abordagem do
/// próprio Material Design.
abstract final class AppShadows {
  static const level0 = <BoxShadow>[];

  static const level1 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const level2 = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const level3 = [
    BoxShadow(color: Color(0x29000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const level4 = [
    BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}
