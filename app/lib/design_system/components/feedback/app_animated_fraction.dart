import 'package:flutter/material.dart';

import '../../animations/app_motion.dart';

/// Barra/valor animado do BORAH (UI-08 §5) — anima de 0 até [value] em
/// vez de saltar direto para o valor final, para qualquer indicador do
/// tipo "preenchimento" (ex.: barra de XP da Gamificação, hoje um
/// `FractionallySizedBox(widthFactor: ...)` estático).
///
/// Reanima do zero sempre que [value] muda (não guarda o valor anterior
/// como ponto de partida) — comportamento correto para o único uso
/// hoje previsto (UI-08B: barra de XP, que preenche uma vez por
/// carregamento de tela, não incrementalmente em tempo real).
///
/// Ainda não conectado a nenhuma tela (UI-08A é só a fundação).
class AppAnimatedFraction extends StatelessWidget {
  const AppAnimatedFraction({
    super.key,
    required this.value,
    required this.child,
    this.duration = AppMotion.celebratory,
    this.curve = AppMotion.emphasized,
  });

  /// Fração final (0.0 a 1.0) — valores fora da faixa são limitados.
  final double value;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: AppMotion.scaled(context, duration),
      curve: curve,
      builder: (context, animatedValue, child) {
        return FractionallySizedBox(widthFactor: animatedValue, child: child);
      },
      child: child,
    );
  }
}
