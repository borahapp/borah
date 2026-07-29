import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/domain/restaurant_search_filters.dart';
import 'package:app/features/restaurants/presentation/pages/restaurants_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class FakeRestaurantSearchFilters extends Fake
    implements RestaurantSearchFilters {}

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

Widget _wrap(MockRestaurantRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const RestaurantsSearchPage()),
      GoRoute(
        path: '/restaurants/new',
        builder: (_, _) => const Scaffold(body: Text('Create Restaurant Page')),
      ),
      GoRoute(
        path: '/restaurants/:id',
        builder: (_, state) => Scaffold(
          body: Text('Restaurant Detail Page ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [restaurantRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockRestaurantRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeRestaurantSearchFilters());
  });

  setUp(() {
    repository = MockRestaurantRepository();
  });

  testWidgets('estado de carregamento mostra indicador ao abrir a tela', (
    tester,
  ) async {
    final completer = Completer<PagedResult<Restaurant>>();
    when(() => repository.search(any())).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('lista restaurantes retornados pela busca', (tester) async {
    when(() => repository.search(any())).thenAnswer(
      (_) async => PagedResult(
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

  testWidgets('estado vazio mostra mensagem de nenhum restaurante', (
    tester,
  ) async {
    when(() => repository.search(any())).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum restaurante encontrado.'), findsOneWidget);
  });

  testWidgets('estado de erro mostra a mensagem retornada pelo repositório', (
    tester,
  ) async {
    when(
      () => repository.search(any()),
    ).thenThrow(const RestaurantRepositoryException('Falha na busca.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Falha na busca.'), findsOneWidget);
  });

  testWidgets('buscar por nome envia o texto digitado como filtro', (
    tester,
  ) async {
    when(() => repository.search(any())).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'pizza');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final captured = verify(
      () => repository.search(captureAny()),
    ).captured.cast<RestaurantSearchFilters>();
    expect(captured.last.query, 'pizza');
  });

  testWidgets('tocar em um restaurante navega para o detalhe', (tester) async {
    when(() => repository.search(any())).thenAnswer(
      (_) async => PagedResult(
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

  testWidgets('tocar em "+" navega para a criação de restaurante', (
    tester,
  ) async {
    when(() => repository.search(any())).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Create Restaurant Page'), findsOneWidget);
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
        when(() => repository.search(any())).thenAnswer(
          (_) async => PagedResult(
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
    when(() => repository.search(any())).thenAnswer(
      (_) async => PagedResult(
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
