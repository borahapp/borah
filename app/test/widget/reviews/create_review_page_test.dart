import 'dart:async';

import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/presentation/pages/create_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

Review _review({String id = 'rv-1', double rating = 4.5}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: 'user-1',
    rating: rating,
    likesCount: 0,
    photosCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(MockReviewRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const CreateReviewPage(restaurantId: 'r-1'),
      ),
      GoRoute(
        path: '/reviews/:id',
        builder: (_, state) => Scaffold(
          body: Text('Review Detail Page ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      reviewRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockReviewRepository repository;

  setUp(() {
    repository = MockReviewRepository();
  });

  testWidgets('renderização inicial mostra os campos e a ação', (tester) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Avaliar restaurante'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.widgetWithText(FilledButton, 'Publicar avaliação'),
      findsOneWidget,
    );
  });

  testWidgets('nota inválida exibe erro de validação e não chama create', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '9');
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar avaliação'));
    await tester.pumpAndSettle();

    expect(find.text('Informe uma nota entre 1 e 5.'), findsOneWidget);
    verifyNever(
      () => repository.create(
        restaurantId: any(named: 'restaurantId'),
        userId: any(named: 'userId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    );
  });

  testWidgets('estado de carregamento mostra indicador no botão', (
    tester,
  ) async {
    final completer = Completer<Review>();
    when(
      () => repository.create(
        restaurantId: any(named: 'restaurantId'),
        userId: any(named: 'userId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '4.5');
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar avaliação'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_review());
    await tester.pumpAndSettle();
  });

  testWidgets('erro ao publicar exibe snackbar com a mensagem', (tester) async {
    when(
      () => repository.create(
        restaurantId: any(named: 'restaurantId'),
        userId: any(named: 'userId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    ).thenThrow(
      const ReviewRepositoryException('Você já avaliou este restaurante.'),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '4.5');
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar avaliação'));
    await tester.pumpAndSettle();

    expect(find.text('Você já avaliou este restaurante.'), findsOneWidget);
  });

  testWidgets('publicação bem-sucedida navega para o detalhe da avaliação', (
    tester,
  ) async {
    when(
      () => repository.create(
        restaurantId: any(named: 'restaurantId'),
        userId: any(named: 'userId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer((_) async => _review());

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '4.5');
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar avaliação'));
    await tester.pumpAndSettle();

    expect(find.text('Review Detail Page rv-1'), findsOneWidget);
  });

  group('responsividade', () {
    for (final size in [
      const Size(320, 640),
      const Size(412, 915),
      const Size(768, 1024),
    ]) {
      testWidgets('renderiza sem overflow em ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.widgetWithText(FilledButton, 'Publicar avaliação'),
          findsOneWidget,
        );
      });
    }
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });
}
