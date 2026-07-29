import 'package:app/core/models/paged_result.dart';
import 'package:app/features/reviews/application/reviews_controller.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/presentation/states/reviews_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

Review _review({String id = 'rv-1', double rating = 4.5}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: 'user-1',
    rating: rating,
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
    expect(container.read(reviewsControllerProvider), isA<ReviewsInitial>());
  });

  test('loadForRestaurant com resultados -> ReviewsLoaded', () async {
    when(
      () => repository.listByRestaurant('r-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_review()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(reviewsControllerProvider.notifier)
        .loadForRestaurant('r-1');

    expect(container.read(reviewsControllerProvider), isA<ReviewsLoaded>());
  });

  test('loadForRestaurant sem resultados -> ReviewsEmpty', () async {
    when(
      () => repository.listByRestaurant('r-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(reviewsControllerProvider.notifier)
        .loadForRestaurant('r-1');

    expect(container.read(reviewsControllerProvider), isA<ReviewsEmpty>());
  });

  test('loadForRestaurant com falha -> ReviewsError', () async {
    when(
      () => repository.listByRestaurant('r-1', page: 1, limit: 20),
    ).thenThrow(const ReviewRepositoryException('Falha na busca.'));

    await container
        .read(reviewsControllerProvider.notifier)
        .loadForRestaurant('r-1');

    expect(container.read(reviewsControllerProvider), isA<ReviewsError>());
  });

  test('loadNextPage avança a página quando há próxima página', () async {
    when(
      () => repository.listByRestaurant('r-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_review()],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listByRestaurant('r-1', page: 2, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_review(id: 'rv-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(reviewsControllerProvider.notifier);
    await notifier.loadForRestaurant('r-1');
    await notifier.loadNextPage();

    final status = container.read(reviewsControllerProvider);
    expect(status, isA<ReviewsLoaded>());
    expect((status as ReviewsLoaded).result.page, 2);
  });
}
