import 'package:flutter/material.dart';

/// Visualizador de foto em tela cheia com zoom (2B.3 - P4) - reutilizável
/// por qualquer feature que já tenha uma galeria de miniaturas (reviews,
/// restaurantes, eventos/rolês, e futuras Memórias): [open] recebe só a
/// lista de URLs já resolvidas (públicas ou assinadas) e o índice inicial
/// - nunca acessa datasource/repository, mesmo princípio de
/// `ReviewSummaryTile`.
///
/// Zoom/pan via `InteractiveViewer` nativo do Flutter - avaliado antes de
/// qualquer dependência externa (`photo_view`); cobre pinça/zoom e
/// arrastar sem precisar de pacote novo.
class BorahPhotoViewer extends StatefulWidget {
  const BorahPhotoViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final int initialIndex;

  /// Abre o visualizador como uma rota de tela cheia sobre a tela atual.
  /// Seguro mesmo com [imageUrls] vazio (ver `build()`) - os 4 pontos de
  /// uso atuais já evitam chamar isto sem fotos, mas o componente não
  /// depende só disso (2B.3-A1).
  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        pageBuilder: (_, _, _) =>
            BorahPhotoViewer(imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<BorahPhotoViewer> createState() => _BorahPhotoViewerState();
}

class _BorahPhotoViewerState extends State<BorahPhotoViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    // 2B.3-A1: com `imageUrls` vazio, `length - 1` seria -1 e
    // `clamp(0, -1)` lançaria (limite superior menor que o inferior) -
    // guarda antes de fazer o clamp em vez de confiar que todo chamador
    // já filtra listas vazias.
    _index = widget.imageUrls.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              const Center(
                child: Text(
                  'Nenhuma foto disponível.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasMultiple = widget.imageUrls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (hasMultiple)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_index + 1}/${widget.imageUrls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            if (hasMultiple && _index > 0)
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                    tooltip: 'Foto anterior',
                    onPressed: () => _goTo(_index - 1),
                  ),
                ),
              ),
            if (hasMultiple && _index < widget.imageUrls.length - 1)
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 32,
                    ),
                    tooltip: 'Próxima foto',
                    onPressed: () => _goTo(_index + 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
