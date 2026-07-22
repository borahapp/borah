import 'package:flutter/material.dart';

/// Indicador de carregamento do BORAH — variante inline/pequena.
///
/// Achado real do levantamento do UI-02: `public_profile_page.dart` já
/// usa um `SizedBox(height: 36, width: 36, child:
/// CircularProgressIndicator(strokeWidth: 2))` para o estado de
/// carregamento do botão de seguir, diferente do padrão de tela cheia
/// (ver [LoadingScreen]). Este componente canoniza essa variante
/// pequena/inline.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: size <= 24 ? 2 : 3),
    );
  }
}

/// Estado de carregamento de tela inteira do BORAH.
///
/// Achado real do levantamento do UI-02: praticamente todo estado de
/// carregamento do app (~25 arquivos) é
/// `Center(child: CircularProgressIndicator())`, repetido tela a tela.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: LoadingIndicator(size: 40));
  }
}
