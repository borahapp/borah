import 'package:flutter/material.dart';

import '../../animations/app_motion.dart';

/// Crossfade de troca de estado do BORAH (UI-08 §5) — envolve só a
/// região que troca de conteúdo (o resultado de um
/// `switch (status) {...}`), nunca a tela inteira, para não reconstruir
/// `AppBar`/navegação a cada mudança de estado.
///
/// Cada filho passado a [child] precisa de uma `Key` distinta por
/// estado (ex.: `ValueKey(status.runtimeType)`) para o
/// [AnimatedSwitcher] interno detectar a troca — mesma exigência do
/// widget padrão do Flutter, só documentada aqui porque é o ponto mais
/// fácil de esquecer ao adotar este componente.
///
/// Amplamente adotado (auditoria de componentes RC-03, FASE B0): mais
/// de 20 telas, do `groups_list_page.dart` ao `feed_page.dart`, sempre
/// com `duration`/`curve` no valor padrão até hoje - os dois parâmetros
/// continuam existindo para o caso de uma tela futura precisar de um
/// ritmo diferente, não por já terem sido usados.
class AppAnimatedSwitcher extends StatelessWidget {
  const AppAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.base,
    this.curve = AppMotion.standard,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.scaled(context, duration),
      switchInCurve: curve,
      switchOutCurve: curve,
      child: child,
    );
  }
}
