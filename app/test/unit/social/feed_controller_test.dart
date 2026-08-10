import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/social/application/feed_controller.dart';
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/domain/feed_item.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:app/features/social/presentation/states/feed_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

FeedActor _actor({String id = 'user-2'}) {
  return FeedActor(
    id: id,
    fullName: 'Bruno Costa',
    username: 'bruno',
    avatarUrl: null,
  );
}

FeedReviewItem _item({String id = 'rv-1', DateTime? createdAt}) {
  return FeedReviewItem(
    review: Review(
      id: id,
      restaurantId: 'r-1',
      userId: 'user-2',
      rating: 4.5,
      likesCount: 0,
      photosCount: 0,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: createdAt ?? DateTime(2026, 1, 1),
    ),
    actor: _actor(),
    restaurantId: 'r-1',
    restaurantName: 'Outback',
    restaurantCoverImage: null,
    likesCount: 0,
    isLikedByUser: false,
    commentsCount: 0,
  );
}

void main() {
  for (final scenario in [
    (
      label: 'FeedForYouController',
      provider: feedForYouControllerProvider,
      stub:
          (MockFeedRepository repository, String userId, {required int page}) =>
              when(() => repository.listForYou(userId, page: page, limit: 20)),
    ),
    (
      label: 'FeedFollowingController',
      provider: feedFollowingControllerProvider,
      stub:
          (MockFeedRepository repository, String userId, {required int page}) =>
              when(
                () => repository.listFollowing(userId, page: page, limit: 20),
              ),
    ),
  ]) {
    group(scenario.label, () {
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
        expect(container.read(scenario.provider), isA<FeedInitial>());
      });

      test('loadForUser com resultados -> FeedLoaded', () async {
        scenario
            .stub(repository, 'user-1', page: 1)
            .thenAnswer(
              (_) async => PagedResult(
                items: [_item()],
                page: 1,
                limit: 20,
                hasNextPage: false,
              ),
            );

        await container.read(scenario.provider.notifier).loadForUser('user-1');

        expect(container.read(scenario.provider), isA<FeedLoaded>());
      });

      test('loadForUser sem resultados -> FeedEmpty', () async {
        scenario
            .stub(repository, 'user-1', page: 1)
            .thenAnswer(
              (_) async => const PagedResult(
                items: [],
                page: 1,
                limit: 20,
                hasNextPage: false,
              ),
            );

        await container.read(scenario.provider.notifier).loadForUser('user-1');

        expect(container.read(scenario.provider), isA<FeedEmpty>());
      });

      test('loadForUser com falha -> FeedError', () async {
        scenario
            .stub(repository, 'user-1', page: 1)
            .thenThrow(const FeedRepositoryException('Falha ao carregar.'));

        await container.read(scenario.provider.notifier).loadForUser('user-1');

        expect(container.read(scenario.provider), isA<FeedError>());
      });

      test(
        'refresh mantém o resultado anterior visível em FeedRefreshing',
        () async {
          scenario
              .stub(repository, 'user-1', page: 1)
              .thenAnswer(
                (_) async => PagedResult(
                  items: [_item()],
                  page: 1,
                  limit: 20,
                  hasNextPage: false,
                ),
              );

          final notifier = container.read(scenario.provider.notifier);
          await notifier.loadForUser('user-1');

          final refreshFuture = notifier.refresh();
          expect(container.read(scenario.provider), isA<FeedRefreshing>());
          await refreshFuture;

          expect(container.read(scenario.provider), isA<FeedLoaded>());
        },
      );

      test('loadNextPage concatena os itens da nova página aos já carregados '
          '(Infinite Scroll) em vez de substituir a lista', () async {
        scenario
            .stub(repository, 'user-1', page: 1)
            .thenAnswer(
              (_) async => PagedResult(
                items: [_item(id: 'rv-1')],
                page: 1,
                limit: 20,
                hasNextPage: true,
              ),
            );
        scenario
            .stub(repository, 'user-1', page: 2)
            .thenAnswer(
              (_) async => PagedResult(
                items: [_item(id: 'rv-2')],
                page: 2,
                limit: 20,
                hasNextPage: false,
              ),
            );

        final notifier = container.read(scenario.provider.notifier);
        await notifier.loadForUser('user-1');
        await notifier.loadNextPage();

        final state = container.read(scenario.provider);
        expect(state, isA<FeedLoaded>());
        final items = (state as FeedLoaded).result.items;
        expect(items.map((i) => i.feedKey), ['review:rv-1', 'review:rv-2']);
      });

      test('falha ao buscar a página seguinte preserva os itens já carregados '
          'e reverte a página', () async {
        scenario
            .stub(repository, 'user-1', page: 1)
            .thenAnswer(
              (_) async => PagedResult(
                items: [_item(id: 'rv-1')],
                page: 1,
                limit: 20,
                hasNextPage: true,
              ),
            );
        scenario
            .stub(repository, 'user-1', page: 2)
            .thenThrow(const FeedRepositoryException('Falha de rede.'));

        final notifier = container.read(scenario.provider.notifier);
        await notifier.loadForUser('user-1');
        await notifier.loadNextPage();

        final state = container.read(scenario.provider);
        expect(state, isA<FeedLoaded>());
        expect((state as FeedLoaded).result.items.map((i) => i.feedKey), [
          'review:rv-1',
        ]);

        scenario
            .stub(repository, 'user-1', page: 2)
            .thenAnswer(
              (_) async => PagedResult(
                items: [_item(id: 'rv-2')],
                page: 2,
                limit: 20,
                hasNextPage: false,
              ),
            );
        await notifier.loadNextPage();

        final finalState = container.read(scenario.provider);
        expect(finalState, isA<FeedLoaded>());
        expect((finalState as FeedLoaded).result.items.map((i) => i.feedKey), [
          'review:rv-1',
          'review:rv-2',
        ]);
        // Página 3 nunca foi estubada - se o controller a tivesse
        // chamado por engano (em vez de rebuscar a 2, que falhou), o
        // mock teria lançado `MissingStubError` e o teste já teria
        // falhado antes desta linha.
      });

      test('concorrência: resposta desatualizada de loadNextPage não '
          'sobrescreve um refresh mais recente', () async {
        scenario
            .stub(repository, 'user-1', page: 1)
            .thenAnswer(
              (_) async => PagedResult(
                items: [_item(id: 'rv-1')],
                page: 1,
                limit: 20,
                hasNextPage: true,
              ),
            );

        final notifier = container.read(scenario.provider.notifier);
        await notifier.loadForUser('user-1');

        final page2Completer = Completer<PagedResult<FeedItem>>();
        scenario
            .stub(repository, 'user-1', page: 2)
            .thenAnswer((_) => page2Completer.future);
        final loadNextPageFuture = notifier.loadNextPage();

        scenario
            .stub(repository, 'user-1', page: 1)
            .thenAnswer(
              (_) async => PagedResult(
                items: [
                  _item(id: 'rv-1'),
                  _item(id: 'rv-3'),
                ],
                page: 1,
                limit: 20,
                hasNextPage: false,
              ),
            );
        final refreshFuture = notifier.refresh();

        page2Completer.complete(
          PagedResult(
            items: [_item(id: 'rv-2')],
            page: 2,
            limit: 20,
            hasNextPage: false,
          ),
        );

        await loadNextPageFuture;
        await refreshFuture;

        final state = container.read(scenario.provider);
        expect(state, isA<FeedLoaded>());
        final items = (state as FeedLoaded).result.items;
        expect(items.map((i) => i.feedKey), ['review:rv-1', 'review:rv-3']);
      });
    });
  }
}
