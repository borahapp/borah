import 'package:flutter/material.dart';

// IV-05: gradiente roxo reconciliado com o valor exato do pacote oficial
// (BORAH_Pacote_Implementacao_Claude/assets/borah/ASSET_MANIFEST.json,
// campo `colors.appIconGradient`) - substitui o valor de 2 tons obtido
// por amostragem de pixel na FASE 7A/UI-01 (documentado à época como a
// melhor aproximação disponível, já que o PDF do manual não listava hex
// para gradientes). O gradiente verde não tem um valor equivalente no
// pacote oficial - mantido como está, ainda por amostragem.
abstract final class BrandGradients {
  /// Valor oficial exato: `#6C47FF` → `#5B2EFF` → `#3D19C7`.
  static const purple = LinearGradient(
    colors: [Color(0xFF6C47FF), Color(0xFF5B2EFF), Color(0xFF3D19C7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Amostrado da arte oficial (FASE 7A/UI-01): `#C2FF02` → `#97D702`.
  /// Sem valor exato equivalente no pacote oficial (IV-01).
  static const green = LinearGradient(
    colors: [Color(0xFFC2FF02), Color(0xFF97D702)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
