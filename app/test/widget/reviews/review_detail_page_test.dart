import 'dart:async';

import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/presentation/pages/review_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

Review _review({
  String id = 'rv-1',
  String userId = 'user-1',
  double rating = 4.5,
  String? comment = 'Muito bom, recomendo!',
  int likesCount = 3,
}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: userId,
    rating: rating,
    comment: comment,
    likesCount: likesCount,
    photosCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  MockReviewRepository repository, {
  String currentUserId = 'user-1',
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const ReviewDetailPage(reviewId: 'rv-1'),
      ),
      GoRoute(
        path: '/reviews/:id/edit',
        builder: (_, state) => Scaffold(
          body: Text('Edit Review Page ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/reviews/:id/comments',
        builder: (_, state) =>
            Scaffold(body: Text('Comments Page ${state.pathParameters['id']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      reviewRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(currentUserId),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockReviewRepository repository;

  setUp(() {
    repository = MockReviewRepository();
  });

  testWidgets('renderização inicial mostra nota, comentário e curtidas', (
    tester,
  ) async {
    when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
    when(
      () => repository.listPhotoUrls('rv-1'),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => repository.isLikedByUser('rv-1', 'user-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Muito bom, recomendo!'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Ver comentários'),
      findsOneWidget,
    );
  });

  testWidgets('conteúdo da avaliação sem comentário não quebra a tela', (
    tester,
  ) async {
    when(
      () => repository.getById('rv-1'),
    ).thenAnswer((_) async => _review(comment: null));
    when(
      () => repository.listPhotoUrls('rv-1'),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => repository.isLikedByUser('rv-1', 'user-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estado de carregamento mostra indicador', (tester) async {
    final completer = Completer<Review>();
    when(() => repository.getById('rv-1')).thenAnswer((_) => completer.future);
    when(
      () => repository.listPhotoUrls('rv-1'),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => repository.isLikedByUser('rv-1', 'user-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_review());
    await tester.pumpAndSettle();
  });

  testWidgets('estado de erro mostra a mensagem retornada pelo repositório', (
    tester,
  ) async {
    when(
      () => repository.getById('rv-1'),
    ).thenThrow(const ReviewRepositoryException('Avaliação não encontrada.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // A tela mostra o erro tanto no corpo (estado ReviewDetailError) quanto
    // via snackbar (listenForReviewDetailErrors) - comportamento real e
    // intencional desta página, diferente de CreateReviewPage (só snackbar).
    expect(find.text('Avaliação não encontrada.'), findsAtLeastNWidgets(1));
  });

  group('ações do autor', () {
    testWidgets('mostra Editar/Excluir quando o usuário é o autor', (
      tester,
    ) async {
      when(
        () => repository.getById('rv-1'),
      ).thenAnswer((_) async => _review(userId: 'user-1'));
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(_wrap(repository, currentUserId: 'user-1'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Editar'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Excluir'), findsOneWidget);
    });

    testWidgets('esconde Editar/Excluir quando o usuário não é o autor', (
      tester,
    ) async {
      when(
        () => repository.getById('rv-1'),
      ).thenAnswer((_) async => _review(userId: 'user-2'));
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(_wrap(repository, currentUserId: 'user-1'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Editar'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Excluir'), findsNothing);
    });
  });

  group('imagens', () {
    testWidgets('exibe as fotos existentes e o botão de adicionar', (
      tester,
    ) async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>['https://x/0.jpg', 'https://x/1.jpg']);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();
      // Image.network nunca carrega de verdade em flutter test (a suíte
      // sempre recebe HTTP 400) - drena as NetworkImageLoadException
      // esperadas para não serem contabilizadas como falha do teste.
      while (tester.takeException() != null) {}

      expect(find.byType(Image), findsWidgets);
      expect(
        find.widgetWithText(OutlinedButton, 'Adicionar foto'),
        findsOneWidget,
      );
    });

    testWidgets('sem fotos não exibe a lista de imagens', (tester) async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(
        find.widgetWithText(OutlinedButton, 'Adicionar foto'),
        findsOneWidget,
      );
    });

    testWidgets('esconde "Adicionar foto" ao atingir o limite de 5', (
      tester,
    ) async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => List.generate(5, (i) => 'https://x/$i.jpg'));
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(find.byType(Image), findsWidgets);
      expect(
        find.widgetWithText(OutlinedButton, 'Adicionar foto'),
        findsNothing,
      );
    });
  });

  testWidgets('tocar no ícone de curtir alterna o estado', (tester) async {
    when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
    when(
      () => repository.listPhotoUrls('rv-1'),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => repository.isLikedByUser('rv-1', 'user-1'),
    ).thenAnswer((_) async => false);
    when(() => repository.like('rv-1', 'user-1')).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    when(
      () => repository.getById('rv-1'),
    ).thenAnswer((_) async => _review(likesCount: 4));
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    verify(() => repository.like('rv-1', 'user-1')).called(1);
  });

  testWidgets('"Ver comentários" navega para a tela de comentários', (
    tester,
  ) async {
    when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
    when(
      () => repository.listPhotoUrls('rv-1'),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => repository.isLikedByUser('rv-1', 'user-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ver comentários'));
    await tester.pumpAndSettle();

    expect(find.text('Comments Page rv-1'), findsOneWidget);
  });

  testWidgets('"Editar" navega para a tela de edição', (tester) async {
    when(
      () => repository.getById('rv-1'),
    ).thenAnswer((_) async => _review(userId: 'user-1'));
    when(
      () => repository.listPhotoUrls('rv-1'),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => repository.isLikedByUser('rv-1', 'user-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(_wrap(repository, currentUserId: 'user-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Review Page rv-1'), findsOneWidget);
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
        when(
          () => repository.getById('rv-1'),
        ).thenAnswer((_) async => _review());
        when(
          () => repository.listPhotoUrls('rv-1'),
        ).thenAnswer((_) async => <String>[]);
        when(
          () => repository.isLikedByUser('rv-1', 'user-1'),
        ).thenAnswer((_) async => false);

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('4.5'), findsOneWidget);
      });
    }
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
    when(
      () => repository.listPhotoUrls('rv-1'),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => repository.isLikedByUser('rv-1', 'user-1'),
    ).thenAnswer((_) async => false);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });
}
