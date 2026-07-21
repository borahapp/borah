import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:app/features/social/presentation/pages/feed_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

Review _review({
  String id = 'rv-1',
  double rating = 4.5,
  String? comment = 'Ótima experiência.',
}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: 'user-2',
    rating: rating,
    comment: comment,
    likesCount: 0,
    photosCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(MockFeedRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const FeedPage()),
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
      feedRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockFeedRepository repository;

  setUp(() {
    repository = MockFeedRepository();
  });

  testWidgets('estado de carregamento mostra indicador ao abrir a tela', (
    tester,
  ) async {
    final completer = Completer<PagedResult<Review>>();
    when(
      () => repository.listForUser('user-1', page: 1, limit: 20),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('listagem do feed mostra as avaliações retornadas', (
    tester,
  ) async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_review()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Ótima experiência.'), findsOneWidget);
  });

  testWidgets('estado vazio mostra mensagem de feed sem avaliações', (
    tester,
  ) async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma avaliação de quem você segue ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('estado de erro mostra a mensagem retornada pelo repositório', (
    tester,
  ) async {
    when(
      () => repository.listForUser('user-1', page: 1, limit: 20),
    ).thenThrow(const FeedRepositoryException('Não foi possível carregar.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar.'), findsOneWidget);
  });

  testWidgets('tocar em uma avaliação navega para o detalhe da avaliação', (
    tester,
  ) async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_review()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('4.5'));
    await tester.pumpAndSettle();

    expect(find.text('Review Detail Page rv-1'), findsOneWidget);
  });

  testWidgets('puxar para atualizar (RefreshIndicator) mantém a lista anterior '
      'visível e reflete o novo resultado ao concluir', (tester) async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_review()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsOneWidget);

    final completer = Completer<PagedResult<Review>>();
    when(
      () => repository.listForUser('user-1', page: 1, limit: 20),
    ).thenAnswer((_) => completer.future);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();

    // FeedRefreshing preserva o resultado anterior (DV-07 §10/§11):
    // o item continua visível mesmo com a atualização em andamento.
    expect(find.text('4.5'), findsOneWidget);

    completer.complete(
      const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    await tester.pumpAndSettle();

    // Após a sincronização concluir sem avaliações (ex.: usuários
    // seguidos deixaram de postar), a lista é atualizada.
    expect(find.text('4.5'), findsNothing);
    expect(
      find.text('Nenhuma avaliação de quem você segue ainda.'),
      findsOneWidget,
    );
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
          () => repository.listForUser('user-1', page: 1, limit: 20),
        ).thenAnswer(
          (_) async => PagedResult(
            items: [_review()],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );

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
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_review()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });
}
