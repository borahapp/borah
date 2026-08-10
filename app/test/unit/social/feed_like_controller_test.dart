import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/social/application/feed_like_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

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

  const args = FeedLikeArgs(
    reviewId: 'rv-1',
    initialIsLiked: false,
    initialLikesCount: 3,
  );

  test('estado inicial reflete os valores recebidos do Feed', () {
    final state = container.read(feedLikeControllerProvider(args));
    expect(state.isLiked, isFalse);
    expect(state.likesCount, 3);
  });

  test(
    'toggle de "não curtido" para "curtido" é otimista e chama like()',
    () async {
      when(() => repository.like('rv-1', 'user-1')).thenAnswer((_) async {});

      await container
          .read(feedLikeControllerProvider(args).notifier)
          .toggle('user-1');

      final state = container.read(feedLikeControllerProvider(args));
      expect(state.isLiked, isTrue);
      expect(state.likesCount, 4);
      verify(() => repository.like('rv-1', 'user-1')).called(1);
    },
  );

  test('toggle de "curtido" para "não curtido" chama unlike()', () async {
    const likedArgs = FeedLikeArgs(
      reviewId: 'rv-1',
      initialIsLiked: true,
      initialLikesCount: 5,
    );
    when(() => repository.unlike('rv-1', 'user-1')).thenAnswer((_) async {});

    await container
        .read(feedLikeControllerProvider(likedArgs).notifier)
        .toggle('user-1');

    final state = container.read(feedLikeControllerProvider(likedArgs));
    expect(state.isLiked, isFalse);
    expect(state.likesCount, 4);
  });

  test('falha no repositório reverte o estado otimista', () async {
    when(
      () => repository.like('rv-1', 'user-1'),
    ).thenThrow(const ReviewRepositoryException('falhou'));

    await container
        .read(feedLikeControllerProvider(args).notifier)
        .toggle('user-1');

    final state = container.read(feedLikeControllerProvider(args));
    expect(state.isLiked, isFalse);
    expect(state.likesCount, 3);
  });
}
