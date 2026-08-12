import 'dart:async';

import 'package:app/design_system/components/media/borah_photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('open() abre em tela cheia com InteractiveViewer', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    unawaited(
      BorahPhotoViewer.open(
        capturedContext,
        imageUrls: const ['https://x/0.jpg'],
      ),
    );
    await tester.pumpAndSettle();
    while (tester.takeException() != null) {}

    expect(find.byType(BorahPhotoViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('com 1 foto não mostra contador nem setas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BorahPhotoViewer(imageUrls: ['https://x/0.jpg'])),
    );
    while (tester.takeException() != null) {}

    expect(find.textContaining('/'), findsNothing);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('com múltiplas fotos mostra contador e navega com as setas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BorahPhotoViewer(
          imageUrls: ['https://x/0.jpg', 'https://x/1.jpg', 'https://x/2.jpg'],
        ),
      ),
    );
    while (tester.takeException() != null) {}

    expect(find.text('1/3'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    while (tester.takeException() != null) {}

    expect(find.text('2/3'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('inicia no initialIndex informado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BorahPhotoViewer(
          imageUrls: ['https://x/0.jpg', 'https://x/1.jpg'],
          initialIndex: 1,
        ),
      ),
    );
    while (tester.takeException() != null) {}

    expect(find.text('2/2'), findsOneWidget);
  });

  // 2B.3-A1 (gap da auditoria): antes, `imageUrls: []` derrubava o widget
  // em `initState()` (`clamp(0, -1)`, limite superior menor que o
  // inferior). Agora mostra um estado vazio explícito, sem exceção.
  testWidgets('com imageUrls vazio não lança exceção e mostra estado vazio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BorahPhotoViewer(imageUrls: [])),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Nenhuma foto disponível.'), findsOneWidget);
    // Não tenta montar PageView/InteractiveViewer sem fotos para
    // renderizar - nenhum índice inexistente é acessado.
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(InteractiveViewer), findsNothing);
    // Fechar continua funcionando no estado vazio.
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('open() com imageUrls vazio não lança exceção (chamada segura)', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    unawaited(BorahPhotoViewer.open(capturedContext, imageUrls: const []));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BorahPhotoViewer), findsOneWidget);
    expect(find.text('Nenhuma foto disponível.'), findsOneWidget);
  });

  // URL deliberadamente inválida (não é um domínio real, nunca resolve) -
  // sem depender de rede real; confirma só que o widget trata a falha de
  // carregamento da imagem sem derrubar a árvore.
  testWidgets('URL de imagem inválida não derruba a árvore de widgets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BorahPhotoViewer(imageUrls: ['not-a-valid-url'])),
    );
    await tester.pumpAndSettle();
    // A falha de carregamento da imagem gera uma NetworkImageLoadException
    // (ou equivalente) capturada pelo Flutter na camada de imagem, não
    // pelo build da árvore - mesmo padrão já usado em outros testes de
    // fotos do projeto (ex.: `review_detail_page_test.dart`).
    while (tester.takeException() != null) {}

    expect(find.byType(BorahPhotoViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('tocar em fechar fecha o visualizador', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    unawaited(
      BorahPhotoViewer.open(
        capturedContext,
        imageUrls: const ['https://x/0.jpg'],
      ),
    );
    await tester.pumpAndSettle();
    while (tester.takeException() != null) {}

    expect(find.byType(BorahPhotoViewer), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    while (tester.takeException() != null) {}

    expect(find.byType(BorahPhotoViewer), findsNothing);
  });
}
