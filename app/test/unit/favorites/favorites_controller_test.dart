import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/favorites/application/favorites_controller.dart';
import 'package:app/features/favorites/data/favorite_repository_impl.dart';
import 'package:app/features/favorites/domain/favorite_repository.dart';
import 'package:app/features/favorites/domain/favorite_sort_by.dart';
import 'package:app/features/favorites/presentation/states/favorites_status.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

Restaurant _restaurant({String id = 'r-1', String name = 'Bar do Zé'}) {
  return Restaurant(
    id: id,
    name: name,
    category: 'Bar',
    totalReviews: 0,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockFavoriteRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFavoriteRepository();
    container = ProviderContainer(
      overrides: [favoriteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FavoritesInitial', () {
    expect(
      container.read(favoritesControllerProvider),
      isA<FavoritesInitial>(),
    );
  });

  test('loadForUser com resultados -> FavoritesLoaded', () async {
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(favoritesControllerProvider.notifier)
        .loadForUser('user-1');

    expect(container.read(favoritesControllerProvider), isA<FavoritesLoaded>());
  });

  test('loadForUser sem resultados -> FavoritesEmpty', () async {
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(favoritesControllerProvider.notifier)
        .loadForUser('user-1');

    expect(container.read(favoritesControllerProvider), isA<FavoritesEmpty>());
  });

  test('loadForUser com falha -> FavoritesError', () async {
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 1,
        limit: 20,
      ),
    ).thenThrow(const FavoriteRepositoryException('Falha ao carregar.'));

    await container
        .read(favoritesControllerProvider.notifier)
        .loadForUser('user-1');

    expect(container.read(favoritesControllerProvider), isA<FavoritesError>());
  });

  test(
    'refresh mantém o resultado anterior visível em FavoritesSyncing',
    () async {
      when(
        () => repository.listForUser(
          'user-1',
          query: null,
          city: null,
          category: null,
          sortBy: FavoriteSortBy.date,
          page: 1,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_restaurant()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      final notifier = container.read(favoritesControllerProvider.notifier);
      await notifier.loadForUser('user-1');

      final refreshFuture = notifier.refresh();
      expect(
        container.read(favoritesControllerProvider),
        isA<FavoritesSyncing>(),
      );
      await refreshFuture;

      expect(
        container.read(favoritesControllerProvider),
        isA<FavoritesLoaded>(),
      );
    },
  );

  test('loadNextPage avança a página quando há próxima página', () async {
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 2,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant(id: 'r-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(favoritesControllerProvider.notifier);
    await notifier.loadForUser('user-1');
    await notifier.loadNextPage();

    final status = container.read(favoritesControllerProvider);
    expect(status, isA<FavoritesLoaded>());
    expect((status as FavoritesLoaded).result.page, 2);
    expect((status).result.items.map((r) => r.id), ['r-1', 'r-2']);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar FavoritesError', () async {
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant(id: 'r-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 2,
        limit: 20,
      ),
    ).thenThrow(const FavoriteRepositoryException('Falha de rede.'));

    final notifier = container.read(favoritesControllerProvider.notifier);
    await notifier.loadForUser('user-1');
    await notifier.loadNextPage();

    final status = container.read(favoritesControllerProvider);
    expect(status, isA<FavoritesLoaded>());
    expect((status as FavoritesLoaded).result.items.map((r) => r.id), ['r-1']);
  });

  test('após falha em loadNextPage, uma nova tentativa rebusca a MESMA '
      'página em vez de pular para a seguinte', () async {
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant(id: 'r-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 2,
        limit: 20,
      ),
    ).thenThrow(const FavoriteRepositoryException('Falha de rede.'));

    final notifier = container.read(favoritesControllerProvider.notifier);
    await notifier.loadForUser('user-1');
    await notifier.loadNextPage(); // página 2 falha

    expect(
      (container.read(favoritesControllerProvider) as FavoritesLoaded)
          .result
          .items
          .map((r) => r.id),
      ['r-1'],
    );

    // A segunda tentativa deve rebuscar a página 2 (a que falhou), nunca
    // pular direto para a 3.
    when(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 2,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant(id: 'r-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );
    await notifier.loadNextPage();

    final finalStatus = container.read(favoritesControllerProvider);
    expect(finalStatus, isA<FavoritesLoaded>());
    expect((finalStatus as FavoritesLoaded).result.items.map((r) => r.id), [
      'r-1',
      'r-2',
    ]);
    verifyNever(
      () => repository.listForUser(
        'user-1',
        query: null,
        city: null,
        category: null,
        sortBy: FavoriteSortBy.date,
        page: 3,
        limit: 20,
      ),
    );
  });

  test(
    'concorrência entre loadNextPage e refresh: a resposta desatualizada '
    'do loadNextPage não sobrescreve o resultado mais recente do refresh',
    () async {
      when(
        () => repository.listForUser(
          'user-1',
          query: null,
          city: null,
          category: null,
          sortBy: FavoriteSortBy.date,
          page: 1,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_restaurant(id: 'r-1')],
          page: 1,
          limit: 20,
          hasNextPage: true,
        ),
      );

      final notifier = container.read(favoritesControllerProvider.notifier);
      await notifier.loadForUser('user-1');

      // loadNextPage (página 2) fica pendente, controlado manualmente.
      final page2Completer = Completer<PagedResult<Restaurant>>();
      when(
        () => repository.listForUser(
          'user-1',
          query: null,
          city: null,
          category: null,
          sortBy: FavoriteSortBy.date,
          page: 2,
          limit: 20,
        ),
      ).thenAnswer((_) => page2Completer.future);
      final loadNextPageFuture = notifier.loadNextPage();

      // Enquanto isso, um refresh mais recente é disparado e reseta para
      // a página 1.
      when(
        () => repository.listForUser(
          'user-1',
          query: null,
          city: null,
          category: null,
          sortBy: FavoriteSortBy.date,
          page: 1,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [
            _restaurant(id: 'r-1'),
            _restaurant(id: 'r-3'),
          ],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      final refreshFuture = notifier.refresh();

      // A resposta da página 2 (mais antiga) chega DEPOIS do refresh já
      // ter assumido - não deve aparecer no resultado final.
      page2Completer.complete(
        PagedResult(
          items: [_restaurant(id: 'r-2')],
          page: 2,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await loadNextPageFuture;
      await refreshFuture;

      final status = container.read(favoritesControllerProvider);
      expect(status, isA<FavoritesLoaded>());
      final items = (status as FavoritesLoaded).result.items;
      expect(items.map((r) => r.id), ['r-1', 'r-3']);
    },
  );
}
