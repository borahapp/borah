import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/gamification/application/ranking_users_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/ranking_entry.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/gamification/presentation/states/ranking_users_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

RankingEntry _entry({String userId = 'user-2'}) {
  return RankingEntry(
    progress: UserProgress(
      userId: userId,
      xp: 100,
      points: 100,
      level: 1,
      updatedAt: DateTime(2026, 1, 1),
    ),
    fullName: 'Maria',
  );
}

void main() {
  late MockGamificationRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockGamificationRepository();
    container = ProviderContainer(
      overrides: [gamificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é RankingUsersInitial', () {
    expect(
      container.read(rankingUsersControllerProvider),
      isA<RankingUsersInitial>(),
    );
  });

  test('load(global) com resultados -> RankingUsersLoaded', () async {
    when(() => repository.listGlobalRanking(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(rankingUsersControllerProvider.notifier)
        .load('user-1', RankingUsersType.global);

    expect(
      container.read(rankingUsersControllerProvider),
      isA<RankingUsersLoaded>(),
    );
    verify(() => repository.listGlobalRanking(page: 1, limit: 20)).called(1);
  });

  test('load(friends) chama listFriendsRanking', () async {
    when(
      () => repository.listFriendsRanking('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_entry()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(rankingUsersControllerProvider.notifier)
        .load('user-1', RankingUsersType.friends);

    verify(
      () => repository.listFriendsRanking('user-1', page: 1, limit: 20),
    ).called(1);
  });

  test('sem resultados -> RankingUsersEmpty', () async {
    when(() => repository.listGlobalRanking(page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(rankingUsersControllerProvider.notifier)
        .load('user-1', RankingUsersType.global);

    expect(
      container.read(rankingUsersControllerProvider),
      isA<RankingUsersEmpty>(),
    );
  });

  test('com falha -> RankingUsersError', () async {
    when(
      () => repository.listGlobalRanking(page: 1, limit: 20),
    ).thenThrow(const GamificationRepositoryException('Falha.'));

    await container
        .read(rankingUsersControllerProvider.notifier)
        .load('user-1', RankingUsersType.global);

    expect(
      container.read(rankingUsersControllerProvider),
      isA<RankingUsersError>(),
    );
  });

  test('loadNextPage concatena os itens da nova página aos já carregados em '
      'vez de substituir a lista', () async {
    when(() => repository.listGlobalRanking(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(() => repository.listGlobalRanking(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(rankingUsersControllerProvider.notifier);
    await notifier.load('user-1', RankingUsersType.global);
    await notifier.loadNextPage();

    final status = container.read(rankingUsersControllerProvider);
    expect(status, isA<RankingUsersLoaded>());
    final items = (status as RankingUsersLoaded).result.items;
    expect(items.map((e) => e.progress.userId), ['user-1', 'user-2']);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar RankingUsersError', () async {
    when(() => repository.listGlobalRanking(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listGlobalRanking(page: 2, limit: 20),
    ).thenThrow(const GamificationRepositoryException('Falha de rede.'));

    final notifier = container.read(rankingUsersControllerProvider.notifier);
    await notifier.load('user-1', RankingUsersType.global);
    await notifier.loadNextPage();

    final status = container.read(rankingUsersControllerProvider);
    expect(status, isA<RankingUsersLoaded>());
    expect(
      (status as RankingUsersLoaded).result.items.map((e) => e.progress.userId),
      ['user-1'],
    );
  });

  test('após falha em loadNextPage, uma nova tentativa rebusca a MESMA '
      'página em vez de pular para a seguinte', () async {
    when(() => repository.listGlobalRanking(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listGlobalRanking(page: 2, limit: 20),
    ).thenThrow(const GamificationRepositoryException('Falha de rede.'));

    final notifier = container.read(rankingUsersControllerProvider.notifier);
    await notifier.load('user-1', RankingUsersType.global);
    await notifier.loadNextPage(); // página 2 falha

    expect(
      (container.read(rankingUsersControllerProvider) as RankingUsersLoaded)
          .result
          .items
          .map((e) => e.progress.userId),
      ['user-1'],
    );

    // A segunda tentativa deve rebuscar a página 2 (a que falhou), nunca
    // pular direto para a 3.
    when(() => repository.listGlobalRanking(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );
    await notifier.loadNextPage();

    final finalStatus = container.read(rankingUsersControllerProvider);
    expect(finalStatus, isA<RankingUsersLoaded>());
    expect(
      (finalStatus as RankingUsersLoaded).result.items.map(
        (e) => e.progress.userId,
      ),
      ['user-1', 'user-2'],
    );
    verifyNever(() => repository.listGlobalRanking(page: 3, limit: 20));
  });

  test('concorrência entre loadNextPage e um novo load: a resposta '
      'desatualizada do loadNextPage não sobrescreve o resultado mais '
      'recente', () async {
    when(() => repository.listGlobalRanking(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(rankingUsersControllerProvider.notifier);
    await notifier.load('user-1', RankingUsersType.global);

    // loadNextPage (página 2) fica pendente, controlado manualmente.
    final page2Completer = Completer<PagedResult<RankingEntry>>();
    when(
      () => repository.listGlobalRanking(page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, o usuário troca para "Entre Amigos" - um novo load
    // mais recente é disparado.
    when(
      () => repository.listFriendsRanking('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-9')],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final loadOtherFuture = notifier.load('user-1', RankingUsersType.friends);

    // A resposta da página 2 do ranking Global chega DEPOIS do novo
    // load já ter assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [_entry(userId: 'user-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await loadNextPageFuture;
    await loadOtherFuture;

    final status = container.read(rankingUsersControllerProvider);
    expect(status, isA<RankingUsersLoaded>());
    final items = (status as RankingUsersLoaded).result.items;
    expect(items.map((e) => e.progress.userId), ['user-9']);
  });
}
