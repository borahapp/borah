import 'package:app/core/models/paged_result.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/social/application/feed_controller.dart';
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:app/features/social/presentation/states/feed_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

Review _review({String id = 'rv-1'}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: 'user-2',
    rating: 4.5,
    likesCount: 0,
    photosCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockFeedRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFeedRepository();
    container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FeedInitial', () {
    expect(container.read(feedControllerProvider), isA<FeedInitial>());
  });

  test('loadForUser com resultados -> FeedLoaded', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_review()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(feedControllerProvider.notifier).loadForUser('user-1');

    expect(container.read(feedControllerProvider), isA<FeedLoaded>());
  });

  test('loadForUser sem resultados -> FeedEmpty', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(feedControllerProvider.notifier).loadForUser('user-1');

    expect(container.read(feedControllerProvider), isA<FeedEmpty>());
  });

  test('loadForUser com falha -> FeedError', () async {
    when(
      () => repository.listForUser('user-1', page: 1, limit: 20),
    ).thenThrow(const FeedRepositoryException('Falha ao carregar.'));

    await container.read(feedControllerProvider.notifier).loadForUser('user-1');

    expect(container.read(feedControllerProvider), isA<FeedError>());
  });

  test(
    'refresh mantém o resultado anterior visível em FeedRefreshing',
    () async {
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

      final notifier = container.read(feedControllerProvider.notifier);
      await notifier.loadForUser('user-1');

      final refreshFuture = notifier.refresh();
      expect(container.read(feedControllerProvider), isA<FeedRefreshing>());
      await refreshFuture;

      expect(container.read(feedControllerProvider), isA<FeedLoaded>());
    },
  );

  test('loadNextPage concatena os itens da nova página aos já carregados '
      '(DV-07 §11 "Infinite Scroll") em vez de substituir a lista', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_review(id: 'rv-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(() => repository.listForUser('user-1', page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_review(id: 'rv-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(feedControllerProvider.notifier);
    await notifier.loadForUser('user-1');
    await notifier.loadNextPage();

    final state = container.read(feedControllerProvider);
    expect(state, isA<FeedLoaded>());
    final items = (state as FeedLoaded).result.items;
    expect(items.map((r) => r.id), ['rv-1', 'rv-2']);
  });
}
