import 'package:flutter/material.dart';

/// Motion Tokens — UI-08 §4. Única fonte de verdade para duração/curva
/// de qualquer animação do BORAH, mesmo papel de [AppSpacing]/[AppRadius]
/// para espaçamento/raio: nenhum widget declara `Duration`/`Curve` cru,
/// só consome estes tokens.
///
/// Faixa de duração (150–500ms) delimitada pela diretriz solta do UI-01
/// §12 ("150 e 300 ms... evitar animações excessivas"), com uma única
/// exceção deliberada ([celebratory], até 500ms) para os 2 momentos que
/// o UI-08 identificou como genuinamente "de marca" (barra de XP e
/// desbloqueio de badge da Gamificação) — não para uso geral.
abstract final class AppMotion {
  /// Microinterações: toggle de ícone (favoritar/curtir), ripple.
  static const fast = Duration(milliseconds: 150);

  /// Crossfade padrão de troca de estado (Loading/Empty/Error/Loaded).
  static const base = Duration(milliseconds: 200);

  /// Transição de página, entrada de dialog/bottom sheet.
  static const slow = Duration(milliseconds: 300);

  /// Uso deliberadamente raro — só barra de XP e desbloqueio de badge
  /// (UI-08 §4/§9: avaliado e descartado qualquer pacote externo para
  /// esse momento, `Curves.elasticOut` nativo já cobre a "celebração").
  static const celebratory = Duration(milliseconds: 500);

  /// Crossfades gerais (entrada e saída simétricas).
  static const standard = Curves.easeInOut;

  /// Entradas — algo aparecendo/crescendo (início rápido, chegada suave).
  static const emphasized = Curves.easeOutCubic;

  /// Saídas/dismiss.
  static const decelerate = Curves.easeOut;

  /// Só o desbloqueio de badge (UI-08 §4) — uso único e deliberado, não
  /// uma curva de uso geral.
  static const bounce = Curves.elasticOut;

  /// Acessibilidade (UI-08 §8): ponto único onde toda duração passa
  /// antes de chegar a um widget animado. Com "Reduzir movimento" ativo
  /// no SO (`MediaQuery.disableAnimations`), a duração colapsa para
  /// zero — o conteúdo troca do mesmo jeito, só sem a transição visual.
  static Duration scaled(BuildContext context, Duration duration) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
  }
}
