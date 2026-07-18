import 'dart:typed_data';

import 'package:app/features/reviews/application/review_detail_controller.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/presentation/states/review_detail_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

Review _review({
  String id = 'rv-1',
  double rating = 4.5,
  int likesCount = 0,
  int photosCount = 0,
}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: 'user-1',
    rating: rating,
    likesCount: likesCount,
    photosCount: photosCount,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockReviewRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockReviewRepository();
    container = ProviderContainer(
      overrides: [reviewRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é ReviewDetailInitial', () {
    expect(
      container.read(reviewDetailControllerProvider),
      isA<ReviewDetailInitial>(),
    );
  });

  group('load', () {
    test('sucesso -> ReviewDetailLoaded', () async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      await container
          .read(reviewDetailControllerProvider.notifier)
          .load('rv-1', currentUserId: 'user-1');

      expect(
        container.read(reviewDetailControllerProvider),
        isA<ReviewDetailLoaded>(),
      );
    });

    test('falha -> ReviewDetailError', () async {
      when(
        () => repository.getById('rv-1'),
      ).thenThrow(const ReviewRepositoryException('Não encontrado.'));

      await container
          .read(reviewDetailControllerProvider.notifier)
          .load('rv-1', currentUserId: 'user-1');

      expect(
        container.read(reviewDetailControllerProvider),
        isA<ReviewDetailError>(),
      );
    });
  });

  group('create', () {
    test('sucesso -> ReviewDetailSaveSuccess', () async {
      when(
        () => repository.create(
          restaurantId: any(named: 'restaurantId'),
          userId: any(named: 'userId'),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => _review());

      await container
          .read(reviewDetailControllerProvider.notifier)
          .create(restaurantId: 'r-1', userId: 'user-1', rating: 4.5);

      expect(
        container.read(reviewDetailControllerProvider),
        isA<ReviewDetailSaveSuccess>(),
      );
    });

    test('falha -> ReviewDetailError', () async {
      when(
        () => repository.create(
          restaurantId: any(named: 'restaurantId'),
          userId: any(named: 'userId'),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
        ),
      ).thenThrow(const ReviewRepositoryException('Já existe uma avaliação.'));

      await container
          .read(reviewDetailControllerProvider.notifier)
          .create(restaurantId: 'r-1', userId: 'user-1', rating: 4.5);

      expect(
        container.read(reviewDetailControllerProvider),
        isA<ReviewDetailError>(),
      );
    });
  });

  group('toggleLike', () {
    test('curte quando ainda não curtido', () async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);
      when(() => repository.like('rv-1', 'user-1')).thenAnswer((_) async {});

      final notifier = container.read(reviewDetailControllerProvider.notifier);
      await notifier.load('rv-1', currentUserId: 'user-1');

      when(
        () => repository.getById('rv-1'),
      ).thenAnswer((_) async => _review(likesCount: 1));

      await notifier.toggleLike('rv-1', 'user-1');

      final status = container.read(reviewDetailControllerProvider);
      expect(status, isA<ReviewDetailSaveSuccess>());
      expect((status as ReviewDetailSaveSuccess).likedByCurrentUser, isTrue);
      verify(() => repository.like('rv-1', 'user-1')).called(1);
    });
  });

  group('addPhoto', () {
    test('bloqueia quando já atingiu o limite de fotos', () async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(() => repository.listPhotoUrls('rv-1')).thenAnswer(
        (_) async => List.generate(maxReviewPhotos, (i) => 'https://x/$i.jpg'),
      );
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      final notifier = container.read(reviewDetailControllerProvider.notifier);
      await notifier.load('rv-1', currentUserId: 'user-1');

      await notifier.addPhoto(
        'rv-1',
        bytes: Uint8List(0),
        fileExtension: 'jpg',
      );

      expect(
        container.read(reviewDetailControllerProvider),
        isA<ReviewDetailError>(),
      );
      verifyNever(
        () => repository.addPhoto(
          any(),
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      );
    });
  });

  group('delete', () {
    test('sucesso -> ReviewDetailDeleted', () async {
      when(() => repository.delete('rv-1')).thenAnswer((_) async {});

      await container
          .read(reviewDetailControllerProvider.notifier)
          .delete('rv-1');

      expect(
        container.read(reviewDetailControllerProvider),
        isA<ReviewDetailDeleted>(),
      );
    });
  });
}
