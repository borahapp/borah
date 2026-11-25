import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/reviews/application/reviewer_ranking_controller.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/domain/reviewer_ranking_entry.dart';
import 'package:app/features/reviews/presentation/states/reviewer_ranking_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

ReviewerRankingEntry _entry({String userId = 'user-2', int reviewsCount = 7}) {
  return ReviewerRankingEntry(
    userId: userId,
    fullName: 'Maria',
    reviewsCount: reviewsCount,
  );
}

void main() {
  late MockReviewRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockReviewRepository();
    container = ProviderContainer(
      overrides: [reviewRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é ReviewerRankingInitial', () {
    expect(
      container.read(reviewerRankingControllerProvider),
      isA<ReviewerRankingInitial>(),
    );
  });

  test('load com resultados -> ReviewerRankingLoaded', () async {
    when(() => repository.listTopReviewers(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(reviewerRankingControllerProvider.notifier).load();

    expect(
      container.read(reviewerRankingControllerProvider),
      isA<ReviewerRankingLoaded>(),
    );
    verify(() => repository.listTopReviewers(page: 1, limit: 20)).called(1);
  });

  test('sem resultados -> ReviewerRankingEmpty', () async {
    when(() => repository.listTopReviewers(page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(reviewerRankingControllerProvider.notifier).load();

    expect(
      container.read(reviewerRankingControllerProvider),
      isA<ReviewerRankingEmpty>(),
    );
  });

  test('com falha -> ReviewerRankingError', () async {
    when(
      () => repository.listTopReviewers(page: 1, limit: 20),
    ).thenThrow(const ReviewRepositoryException('Falha.'));

    await container.read(reviewerRankingControllerProvider.notifier).load();

    expect(
      container.read(reviewerRankingControllerProvider),
      isA<ReviewerRankingError>(),
    );
  });

  test('loadNextPage concatena os itens da nova página aos já carregados em '
      'vez de substituir a lista', () async {
    when(() => repository.listTopReviewers(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(() => repository.listTopReviewers(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(reviewerRankingControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(reviewerRankingControllerProvider);
    expect(status, isA<ReviewerRankingLoaded>());
    final items = (status as ReviewerRankingLoaded).result.items;
    expect(items.map((e) => e.userId), ['user-1', 'user-2']);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar ReviewerRankingError', () async {
    when(() => repository.listTopReviewers(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listTopReviewers(page: 2, limit: 20),
    ).thenThrow(const ReviewRepositoryException('Falha de rede.'));

    final notifier = container.read(reviewerRankingControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(reviewerRankingControllerProvider);
    expect(status, isA<ReviewerRankingLoaded>());
    expect(
      (status as ReviewerRankingLoaded).result.items.map((e) => e.userId),
      ['user-1'],
    );
  });

  test('após falha em loadNextPage, uma nova tentativa rebusca a MESMA '
      'página em vez de pular para a seguinte', () async {
    when(() => repository.listTopReviewers(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listTopReviewers(page: 2, limit: 20),
    ).thenThrow(const ReviewRepositoryException('Falha de rede.'));

    final notifier = container.read(reviewerRankingControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage(); // página 2 falha

    expect(
      (container.read(reviewerRankingControllerProvider) as ReviewerRankingLoaded)
          .result
          .items
          .map((e) => e.userId),
      ['user-1'],
    );

    when(() => repository.listTopReviewers(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );
    await notifier.loadNextPage();

    final finalStatus = container.read(reviewerRankingControllerProvider);
    expect(finalStatus, isA<ReviewerRankingLoaded>());
    expect(
      (finalStatus as ReviewerRankingLoaded).result.items.map((e) => e.userId),
      ['user-1', 'user-2'],
    );
    verifyNever(() => repository.listTopReviewers(page: 3, limit: 20));
  });

  test('concorrência entre loadNextPage e um novo load: a resposta '
      'desatualizada do loadNextPage não sobrescreve o resultado mais '
      'recente', () async {
    when(() => repository.listTopReviewers(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(reviewerRankingControllerProvider.notifier);
    await notifier.load();

    final page2Completer = Completer<PagedResult<ReviewerRankingEntry>>();
    when(
      () => repository.listTopReviewers(page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    when(() => repository.listTopReviewers(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(userId: 'user-9')],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final loadOtherFuture = notifier.load();

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

    final status = container.read(reviewerRankingControllerProvider);
    expect(status, isA<ReviewerRankingLoaded>());
    final items = (status as ReviewerRankingLoaded).result.items;
    expect(items.map((e) => e.userId), ['user-9']);
  });
}
