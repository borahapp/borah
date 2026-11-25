import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/rankings/application/rankings_controller.dart';
import 'package:app/features/rankings/data/ranking_repository_impl.dart';
import 'package:app/features/rankings/domain/ranked_restaurant.dart';
import 'package:app/features/rankings/domain/ranking_repository.dart';
import 'package:app/features/rankings/domain/ranking_scope.dart';
import 'package:app/features/rankings/presentation/states/rankings_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRankingRepository extends Mock implements RankingRepository {}

RankedRestaurant _ranked({String id = 'r-1', String name = 'Bar do Zé'}) {
  return RankedRestaurant(
    restaurantId: id,
    name: name,
    category: 'Bar',
    rating: 4.5,
    reviewsCount: 10,
  );
}

void main() {
  late MockRankingRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(RankingScope.global);
  });

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

  test('load sem argumentos usa escopo Global, sem filtros', () async {
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          PagedResult(items: [_ranked()], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(rankingsControllerProvider.notifier).load();

    expect(container.read(rankingsControllerProvider), isA<RankingsLoaded>());
  });

  test('load com escopo Pessoal repassa o userId', () async {
    when(
      () => repository.list(
        scope: RankingScope.personal,
        groupId: null,
        userId: 'user-1',
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          PagedResult(items: [_ranked()], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(rankingsControllerProvider.notifier)
        .load(scope: RankingScope.personal, userId: 'user-1');

    expect(container.read(rankingsControllerProvider), isA<RankingsLoaded>());
  });

  test('load com escopo Grupo repassa o groupId', () async {
    when(
      () => repository.list(
        scope: RankingScope.group,
        groupId: 'group-1',
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          PagedResult(items: [_ranked()], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(rankingsControllerProvider.notifier)
        .load(scope: RankingScope.group, groupId: 'group-1');

    expect(container.read(rankingsControllerProvider), isA<RankingsLoaded>());
  });

  test('load com filtros repassa cidade, estado, país e categoria', () async {
    ({String? city, String? state, String? country, String? category})?
    captured;
    when(
      () => repository.list(
        scope: any(named: 'scope'),
        groupId: any(named: 'groupId'),
        userId: any(named: 'userId'),
        city: any(named: 'city'),
        state: any(named: 'state'),
        country: any(named: 'country'),
        category: any(named: 'category'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      captured = (
        city: invocation.namedArguments[#city] as String?,
        state: invocation.namedArguments[#state] as String?,
        country: invocation.namedArguments[#country] as String?,
        category: invocation.namedArguments[#category] as String?,
      );
      return PagedResult(
        items: [_ranked()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      );
    });

    await container
        .read(rankingsControllerProvider.notifier)
        .load(
          city: 'São Paulo',
          state: 'SP',
          country: 'Brasil',
          category: 'Bar',
        );

    expect(captured?.city, 'São Paulo');
    expect(captured?.state, 'SP');
    expect(captured?.country, 'Brasil');
    expect(captured?.category, 'Bar');
  });

  test('load sem resultados -> RankingsEmpty', () async {
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(rankingsControllerProvider.notifier).load();

    expect(container.read(rankingsControllerProvider), isA<RankingsEmpty>());
  });

  test('load com falha -> RankingsError', () async {
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenThrow(const RankingRepositoryException('Falha ao carregar.'));

    await container.read(rankingsControllerProvider.notifier).load();

    expect(container.read(rankingsControllerProvider), isA<RankingsError>());
  });

  test('loadNextPage avança a página quando há próxima página', () async {
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          PagedResult(items: [_ranked()], page: 1, limit: 20, hasNextPage: true),
    );
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 2,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_ranked(id: 'r-2')],
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
    expect(status.result.items.map((r) => r.restaurantId), ['r-1', 'r-2']);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar RankingsError', () async {
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          PagedResult(items: [_ranked()], page: 1, limit: 20, hasNextPage: true),
    );
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 2,
        limit: 20,
      ),
    ).thenThrow(const RankingRepositoryException('Falha de rede.'));

    final notifier = container.read(rankingsControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(rankingsControllerProvider);
    expect(status, isA<RankingsLoaded>());
    expect(
      (status as RankingsLoaded).result.items.map((r) => r.restaurantId),
      ['r-1'],
    );
  });

  test('concorrência entre loadNextPage e um novo load (troca de escopo): a '
      'resposta desatualizada do loadNextPage não sobrescreve o resultado '
      'mais recente', () async {
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          PagedResult(items: [_ranked()], page: 1, limit: 20, hasNextPage: true),
    );

    final notifier = container.read(rankingsControllerProvider.notifier);
    await notifier.load();

    // loadNextPage (página 2, escopo Global) fica pendente, controlado
    // manualmente.
    final page2Completer = Completer<PagedResult<RankedRestaurant>>();
    when(
      () => repository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 2,
        limit: 20,
      ),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, o usuário troca para o escopo Pessoal - um novo load
    // mais recente é disparado.
    when(
      () => repository.list(
        scope: RankingScope.personal,
        groupId: null,
        userId: 'user-1',
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_ranked(id: 'r-9')],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final loadOtherFuture = notifier.load(
      scope: RankingScope.personal,
      userId: 'user-1',
    );

    // A resposta da página 2 (Global) chega DEPOIS do novo load já ter
    // assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [_ranked(id: 'r-2')],
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
    expect(items.map((r) => r.restaurantId), ['r-9']);
  });
}
