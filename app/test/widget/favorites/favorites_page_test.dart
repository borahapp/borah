import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/favorites/application/favorites_controller.dart';
import 'package:app/features/favorites/data/favorite_repository_impl.dart';
import 'package:app/features/favorites/domain/favorite_repository.dart';
import 'package:app/features/favorites/domain/favorite_sort_by.dart';
import 'package:app/features/favorites/presentation/pages/favorites_page.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

Restaurant _restaurant({
  String id = 'r-1',
  String name = 'Bar do Zé',
  double? averageRating = 4.5,
}) {
  return Restaurant(
    id: id,
    name: name,
    category: 'Bar',
    city: 'São Paulo',
    averageRating: averageRating,
    totalReviews: 3,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// Stub genérico para `listForUser`, cobrindo todos os parâmetros
/// nomeados (mesmos exigidos pelo mocktail para `any(named: ...)`).
void _stubListForUser(
  MockFavoriteRepository repository,
  Future<PagedResult<Restaurant>> Function() answer,
) {
  when(
    () => repository.listForUser(
      any(),
      query: any(named: 'query'),
      city: any(named: 'city'),
      category: any(named: 'category'),
      sortBy: any(named: 'sortBy'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) => answer());
}

/// Constrói a árvore de widgets com `ProviderScope` + `MaterialApp.router`
/// (mesmo padrão consolidado no Tier 1/Tier 2). Quando [container] é
/// informado, ele é reaproveitado (via `UncontrolledProviderScope`) para
/// permitir que o teste dispare `refresh()` diretamente no controller,
/// simulando uma atualização em segundo plano (DV-06 §10/§11) - não há,
/// hoje, nenhum gesto de "puxar para atualizar" na tela que dispare isso.
Widget _wrap(
  MockFavoriteRepository repository, {
  ProviderContainer? container,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const FavoritesPage()),
      GoRoute(
        path: '/restaurants/:id',
        builder: (_, state) => Scaffold(
          body: Text('Restaurant Detail Page ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  if (container != null) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  return ProviderScope(
    overrides: [
      favoriteRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockFavoriteRepository repository;

  setUpAll(() {
    registerFallbackValue(FavoriteSortBy.date);
  });

  setUp(() {
    repository = MockFavoriteRepository();
  });

  testWidgets('estado de carregamento mostra indicador ao abrir a tela', (
    tester,
  ) async {
    final completer = Completer<PagedResult<Restaurant>>();
    _stubListForUser(repository, () => completer.future);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('estado com favoritos mostra os restaurantes retornados', (
    tester,
  ) async {
    _stubListForUser(
      repository,
      () async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Bar do Zé'), findsOneWidget);
    expect(find.text('Bar · São Paulo'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
  });

  testWidgets('estado vazio mostra mensagem de nenhum favorito', (
    tester,
  ) async {
    _stubListForUser(
      repository,
      () async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Você ainda não tem favoritos.'), findsOneWidget);
  });

  testWidgets('estado de erro mostra a mensagem retornada pelo repositório', (
    tester,
  ) async {
    when(
      () => repository.listForUser(
        any(),
        query: any(named: 'query'),
        city: any(named: 'city'),
        category: any(named: 'category'),
        sortBy: any(named: 'sortBy'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(
      const FavoriteRepositoryException('Não foi possível carregar.'),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar.'), findsOneWidget);
  });

  testWidgets('buscar por nome envia o texto digitado como filtro', (
    tester,
  ) async {
    _stubListForUser(
      repository,
      () async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'pizza');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final captured = verify(
      () => repository.listForUser(
        any(),
        query: captureAny(named: 'query'),
        city: any(named: 'city'),
        category: any(named: 'category'),
        sortBy: any(named: 'sortBy'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).captured;
    expect(captured.last, 'pizza');
  });

  testWidgets('filtrar por cidade envia o texto digitado como filtro', (
    tester,
  ) async {
    _stubListForUser(
      repository,
      () async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'São Paulo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final captured = verify(
      () => repository.listForUser(
        any(),
        query: any(named: 'query'),
        city: captureAny(named: 'city'),
        category: any(named: 'category'),
        sortBy: any(named: 'sortBy'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).captured;
    expect(captured.last, 'São Paulo');
  });

  testWidgets('selecionar ordenação por nome envia o critério escolhido', (
    tester,
  ) async {
    _stubListForUser(
      repository,
      () async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<FavoriteSortBy>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nome').last);
    await tester.pumpAndSettle();

    final captured = verify(
      () => repository.listForUser(
        any(),
        query: any(named: 'query'),
        city: any(named: 'city'),
        category: any(named: 'category'),
        sortBy: captureAny(named: 'sortBy'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).captured;
    expect(captured.last, FavoriteSortBy.name);
  });

  testWidgets('tocar em um favorito navega para o detalhe do restaurante', (
    tester,
  ) async {
    _stubListForUser(
      repository,
      () async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bar do Zé'));
    await tester.pumpAndSettle();

    expect(find.text('Restaurant Detail Page r-1'), findsOneWidget);
  });

  testWidgets('estado "syncing" mantém a lista anterior visível durante a '
      'atualização em segundo plano', (tester) async {
    _stubListForUser(
      repository,
      () async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        favoriteRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue('user-1'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(repository, container: container));
    await tester.pumpAndSettle();

    expect(find.text('Bar do Zé'), findsOneWidget);

    final completer = Completer<PagedResult<Restaurant>>();
    _stubListForUser(repository, () => completer.future);

    unawaited(container.read(favoritesControllerProvider.notifier).refresh());
    await tester.pump();

    // FavoritesSyncing preserva o resultado anterior (DV-06 §10/§11):
    // o item continua visível mesmo com uma atualização em andamento.
    expect(find.text('Bar do Zé'), findsOneWidget);

    completer.complete(
      const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    await tester.pumpAndSettle();

    // Após a sincronização concluir sem o restaurante (removido dos
    // favoritos em outro dispositivo/tela), a lista é atualizada.
    expect(find.text('Bar do Zé'), findsNothing);
    expect(find.text('Você ainda não tem favoritos.'), findsOneWidget);
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
        _stubListForUser(
          repository,
          () async => PagedResult(
            items: [_restaurant()],
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
        expect(find.text('Bar do Zé'), findsOneWidget);
      });
    }
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    _stubListForUser(
      repository,
      () async => PagedResult(
        items: [_restaurant()],
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
