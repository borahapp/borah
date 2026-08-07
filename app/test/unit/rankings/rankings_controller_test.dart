import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/rankings/application/rankings_controller.dart';
import 'package:app/features/rankings/data/ranking_repository_impl.dart';
import 'package:app/features/rankings/domain/ranking_repository.dart';
import 'package:app/features/rankings/presentation/states/rankings_status.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRankingRepository extends Mock implements RankingRepository {}

Restaurant _restaurant({String id = 'r-1', String name = 'Bar do Zé'}) {
  return Restaurant(
    id: id,
    name: name,
    category: 'Bar',
    averageRating: 4.5,
    totalReviews: 10,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockRankingRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockRankingRepository();
    container = ProviderContainer(
      overrides: [rankingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é RankingsInitial', () {
    expect(container.read(rankingsControllerProvider), isA<RankingsInitial>());
  });

  test('load geral (sem filtros) com resultados -> RankingsLoaded', () async {
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(rankingsControllerProvider.notifier).load();

    expect(container.read(rankingsControllerProvider), isA<RankingsLoaded>());
  });

  test('load com filtros repassa cidade e categoria', () async {
    ({String? city, String? category})? captured;
    when(
      () => repository.listRanked(
        city: any(named: 'city'),
        category: any(named: 'category'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      captured = (
        city: invocation.namedArguments[#city] as String?,
        category: invocation.namedArguments[#category] as String?,
      );
      return PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      );
    });

    await container
        .read(rankingsControllerProvider.notifier)
        .load(city: 'São Paulo', category: 'Bar');

    expect(captured?.city, 'São Paulo');
    expect(captured?.category, 'Bar');
  });

  test('load sem resultados -> RankingsEmpty', () async {
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(rankingsControllerProvider.notifier).load();

    expect(container.read(rankingsControllerProvider), isA<RankingsEmpty>());
  });

  test('load com falha -> RankingsError', () async {
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 1, limit: 20),
    ).thenThrow(const RankingRepositoryException('Falha ao carregar.'));

    await container.read(rankingsControllerProvider.notifier).load();

    expect(container.read(rankingsControllerProvider), isA<RankingsError>());
  });

  test('loadNextPage avança a página quando há próxima página', () async {
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 2, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant(id: 'r-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(rankingsControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(rankingsControllerProvider);
    expect(status, isA<RankingsLoaded>());
    expect((status as RankingsLoaded).result.page, 2);
    expect(status.result.items.map((r) => r.id), ['r-1', 'r-2']);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar RankingsError', () async {
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 2, limit: 20),
    ).thenThrow(const RankingRepositoryException('Falha de rede.'));

    final notifier = container.read(rankingsControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(rankingsControllerProvider);
    expect(status, isA<RankingsLoaded>());
    expect((status as RankingsLoaded).result.items.map((r) => r.id), ['r-1']);
  });

  test('concorrência entre loadNextPage e um novo load (filtro aplicado): a '
      'resposta desatualizada do loadNextPage não sobrescreve o resultado '
      'mais recente', () async {
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant(id: 'r-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(rankingsControllerProvider.notifier);
    await notifier.load();

    // loadNextPage (página 2) fica pendente, controlado manualmente.
    final page2Completer = Completer<PagedResult<Restaurant>>();
    when(
      () =>
          repository.listRanked(city: null, category: null, page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, o usuário aplica um filtro de cidade - um novo
    // load mais recente é disparado.
    when(
      () => repository.listRanked(
        city: 'São Paulo',
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant(id: 'r-9')],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final loadOtherFuture = notifier.load(city: 'São Paulo');

    // A resposta da página 2 do ranking sem filtro chega DEPOIS do novo
    // load já ter assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [_restaurant(id: 'r-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await loadNextPageFuture;
    await loadOtherFuture;

    final status = container.read(rankingsControllerProvider);
    expect(status, isA<RankingsLoaded>());
    final items = (status as RankingsLoaded).result.items;
    expect(items.map((r) => r.id), ['r-9']);
  });
}
