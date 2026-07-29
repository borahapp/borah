import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';

/// Placeholder de carregamento do BORAH (efeito de "respiração"/pulso).
///
/// Componente novo — o app hoje não tem nenhum estado de skeleton, só
/// o spinner centralizado (ver [LoadingScreen] em `loading_indicator.dart`).
/// Não fica migrado a nenhuma tela nesta rodada.
///
/// Duração de 900ms por ciclo: é uma animação ambiente contínua
/// (diferente das microinterações de 150–300ms do UI-01 §12, que são
/// respostas diretas a um toque) — mesma ordem de grandeza usada por
/// implementações de skeleton loading amplamente adotadas.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, this.width, this.height = 16, this.radius});

  final double? width;
  final double height;
  final BorderRadius? radius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: widget.radius ?? AppRadius.radiusSm,
        ),
      ),
    );
  }
}
