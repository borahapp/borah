import 'package:app/design_system/components/media/borah_photo_viewer.dart';
import 'package:app/features/reviews/presentation/widgets/review_photo_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(List<String> photoUrls) {
  return MaterialApp(
    home: Scaffold(body: ReviewPhotoGrid(photoUrls: photoUrls)),
  );
}

void main() {
  testWidgets('sem fotos, não renderiza nada nem quebra', (tester) async {
    await tester.pumpWidget(_wrap(const []));

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('com fotos, mostra uma miniatura por URL', (tester) async {
    await tester.pumpWidget(
      _wrap(const [
        'https://x/photo-1.jpg',
        'https://x/photo-2.jpg',
        'https://x/photo-3.jpg',
      ]),
    );
    // URLs falsas disparam `NetworkImageLoadException` ao tentar carregar
    // de verdade - mesmo padrão já usado em `change_avatar_page_test.dart`
    // para drenar essas exceções sem falhar o teste (não é o que este
    // teste quer verificar).
    while (tester.takeException() != null) {}

    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('tocar numa miniatura abre o BorahPhotoViewer já na foto '
      'tocada', (tester) async {
    await tester.pumpWidget(
      _wrap(const ['https://x/photo-1.jpg', 'https://x/photo-2.jpg']),
    );
    while (tester.takeException() != null) {}

    await tester.tap(find.byType(Image).at(1));
    await tester.pumpAndSettle();
    while (tester.takeException() != null) {}

    expect(find.byType(BorahPhotoViewer), findsOneWidget);
    final viewer = tester.widget<BorahPhotoViewer>(
      find.byType(BorahPhotoViewer),
    );
    expect(viewer.initialIndex, 1);
    expect(viewer.imageUrls, ['https://x/photo-1.jpg', 'https://x/photo-2.jpg']);
  });
}
