import 'package:app/core/models/paged_result.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/presentation/states/reviews_status.dart';
import 'package:app/features/social/application/user_reviews_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

Review _review({String id = 'rv-1'}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: 'user-1',
    rating: 4.5,
    likesCount: 0,
    photosCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
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

  test('estado inicial é ReviewsInitial', () {
    expect(
      container.read(userReviewsControllerProvider),
      isA<ReviewsInitial>(),
    );
  });

  test('loadForUser com resultados -> ReviewsLoaded', () async {
    when(() => repository.listByUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_review()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(userReviewsControllerProvider.notifier)
        .loadForUser('user-1');

    expect(container.read(userReviewsControllerProvider), isA<ReviewsLoaded>());
  });

  test('loadForUser sem resultados -> ReviewsEmpty', () async {
    when(() => repository.listByUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(userReviewsControllerProvider.notifier)
        .loadForUser('user-1');

    expect(container.read(userReviewsControllerProvider), isA<ReviewsEmpty>());
  });

  test('loadForUser com falha -> ReviewsError', () async {
    when(
      () => repository.listByUser('user-1', page: 1, limit: 20),
    ).thenThrow(const ReviewRepositoryException('Falha na busca.'));

    await container
        .read(userReviewsControllerProvider.notifier)
        .loadForUser('user-1');

    expect(container.read(userReviewsControllerProvider), isA<ReviewsError>());
  });

  group('removeReview', () {
    test('remove a review indicada da lista já carregada', () async {
      when(
        () => repository.listByUser('user-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [
            _review(id: 'rv-1'),
            _review(id: 'rv-2'),
          ],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      final notifier = container.read(userReviewsControllerProvider.notifier);
      await notifier.loadForUser('user-1');
      notifier.removeReview('rv-1');

      final status =
          container.read(userReviewsControllerProvider) as ReviewsLoaded;
      expect(status.result.items.map((r) => r.id), ['rv-2']);
    });

    test(
      'lista fica vazia -> ReviewsEmpty quando remove o último item',
      () async {
        when(
          () => repository.listByUser('user-1', page: 1, limit: 20),
        ).thenAnswer(
          (_) async => PagedResult(
            items: [_review(id: 'rv-1')],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );

        final notifier = container.read(userReviewsControllerProvider.notifier);
        await notifier.loadForUser('user-1');
        notifier.removeReview('rv-1');

        expect(
          container.read(userReviewsControllerProvider),
          isA<ReviewsEmpty>(),
        );
      },
    );

    test('não faz nada quando a lista ainda não foi carregada', () {
      container
          .read(userReviewsControllerProvider.notifier)
          .removeReview('rv-1');

      expect(
        container.read(userReviewsControllerProvider),
        isA<ReviewsInitial>(),
      );
    });
  });
}
