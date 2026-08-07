import 'package:flutter/material.dart';

import '../../animations/app_motion.dart';

/// Pulso de ícone do BORAH (UI-08 §5) — microinteração para toggles
/// como favoritar/curtir: um pequeno "salto" de escala sempre que
/// [trigger] muda de valor (ex.: `isFavorited`/`isLiked`), sem precisar
/// de um `AnimationController` próprio por tela.
///
/// [trigger] é comparado por igualdade (`!=`) a cada rebuild — qualquer
/// tipo serve (bool, enum, etc.), só precisa mudar de valor exatamente
/// quando o ícone deve pulsar.
///
/// Conectado a 3 telas (auditoria de componentes RC-03, FASE B0):
/// favoritar restaurante (`restaurant_detail_page.dart`), curtir
/// avaliação (`review_detail_page.dart`) e badge conquistado
/// (`gamification_profile_page.dart`).
class AppPulseIcon extends StatefulWidget {
  const AppPulseIcon({super.key, required this.trigger, required this.child});

  final Object trigger;
  final Widget child;

  @override
  State<AppPulseIcon> createState() => _AppPulseIconState();
}

class _AppPulseIconState extends State<AppPulseIcon> {
  double _scale = 1.0;

  @override
  void didUpdateWidget(covariant AppPulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      setState(() => _scale = 1.3);
      Future.delayed(AppMotion.scaled(context, AppMotion.fast), () {
        if (mounted) setState(() => _scale = 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: AppMotion.scaled(context, AppMotion.fast),
      curve: AppMotion.bounce,
      child: widget.child,
    );
  }
}
