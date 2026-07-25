import 'package:flutter/material.dart';

import '../../animations/app_motion.dart';

/// Entrada escalonada de item de lista do BORAH (UI-08 §5/§7) — usada
/// quando uma lista recarrega por inteiro (busca, filtro, ranking) e
/// não quando itens são inseridos/removidos individualmente com a tela
/// já montada (esse segundo caso é `AnimatedList`, não este widget).
///
/// [index] decide o atraso: cada item além do primeiro entra ~30ms
/// depois do anterior, num orçamento de tempo único e compartilhado
/// (via `Interval`) — não um `AnimationController`/delay por item, que
/// acumularia tempo real de entrada em listas longas. [maxStaggeredIndex]
/// limita esse acúmulo: itens além dele entram junto com o último
/// (UI-08 §7: "limitar o efeito aos primeiros ~8-10 itens visíveis").
///
/// Envolvido em `RepaintBoundary` (UI-08 §7) para isolar o repaint da
/// animação do resto da lista.
///
/// Ainda não conectado a nenhuma tela (UI-08A é só a fundação).
class AppStaggeredListItem extends StatelessWidget {
  const AppStaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.maxStaggeredIndex = 8,
  });

  final int index;
  final Widget child;
  final int maxStaggeredIndex;

  static const _perItemDelay = Duration(milliseconds: 30);

  @override
  Widget build(BuildContext context) {
    final effectiveIndex = index.clamp(0, maxStaggeredIndex);
    final totalDuration = AppMotion.scaled(
      context,
      AppMotion.fast + _perItemDelay * maxStaggeredIndex,
    );
    final delayFraction = totalDuration == Duration.zero
        ? 0.0
        : (_perItemDelay * effectiveIndex).inMilliseconds /
              totalDuration.inMilliseconds;

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: totalDuration,
        curve: Interval(
          delayFraction.clamp(0.0, 1.0),
          1.0,
          curve: AppMotion.emphasized,
        ),
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 12),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}
