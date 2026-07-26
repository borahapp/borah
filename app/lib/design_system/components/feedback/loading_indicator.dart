import 'package:flutter/material.dart';

import '../../tokens/app_gradients.dart';

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
///
/// Continua com o spinner padrão — vários testes de widget (ex.:
/// `restaurants_search_page_test.dart`, `favorites_page_test.dart`,
/// `feed_page_test.dart`) verificam `find.byType(CircularProgressIndicator)`
/// para o estado de carregamento de listagens. O loop oficial de
/// loading do BORAH (assets/loading/, ver assets/ASSETS.md) é usado
/// especificamente na Splash (`BorahSplashLoader`, mesmo arquivo) — o
/// "loading do aplicativo" descrito no material oficial é o momento de
/// bootstrap, não cada spinner de lista.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: LoadingIndicator(size: 40));
  }
}

/// Loop oficial de loading do BORAH (bootstrap/Splash) — WebP animado e
/// transparente, tamanho original preservado (área livre ao redor do
/// símbolo, sem esticar, por instrução do material oficial), sobre o
/// gradiente roxo oficial (UI-01, `AppGradients`) — primeiro uso real
/// do gradiente em uma tela desde que foi definido.
class BorahSplashLoader extends StatelessWidget {
  const BorahSplashLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final gradients = AppGradients.of(context);

    return Container(
      decoration: BoxDecoration(gradient: gradients.purple),
      child: const Center(
        child: Image(
          image: AssetImage(
            'assets/borah/animations/borah_loading_transparent.webp',
          ),
          width: 160,
          height: 160,
        ),
      ),
    );
  }
}
