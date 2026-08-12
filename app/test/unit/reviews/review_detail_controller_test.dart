import 'dart:async';
import 'dart:typed_data';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/reviews/application/review_detail_controller.dart';
import 'package:app/features/reviews/application/reviews_controller.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/presentation/states/review_detail_status.dart';
import 'package:app/features/reviews/presentation/states/reviews_status.dart';
import 'package:app/features/social/application/user_reviews_controller.dart';
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
          ambienceScore: any(named: 'ambienceScore'),
          serviceScore: any(named: 'serviceScore'),
          foodScore: any(named: 'foodScore'),
          costBenefitScore: any(named: 'costBenefitScore'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => _review());

      await container
          .read(reviewDetailControllerProvider.notifier)
          .create(
            restaurantId: 'r-1',
            userId: 'user-1',
            rating: 4.5,
            ambienceScore: 4,
            serviceScore: 4,
            foodScore: 5,
            costBenefitScore: 4,
          );

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
          ambienceScore: any(named: 'ambienceScore'),
          serviceScore: any(named: 'serviceScore'),
          foodScore: any(named: 'foodScore'),
          costBenefitScore: any(named: 'costBenefitScore'),
          comment: any(named: 'comment'),
        ),
      ).thenThrow(const ReviewRepositoryException('Já existe uma avaliação.'));

      await container
          .read(reviewDetailControllerProvider.notifier)
          .create(
            restaurantId: 'r-1',
            userId: 'user-1',
            rating: 4.5,
            ambienceScore: 4,
            serviceScore: 4,
            foodScore: 5,
            costBenefitScore: 4,
          );

      expect(
        container.read(reviewDetailControllerProvider),
        isA<ReviewDetailError>(),
      );
    });
  });

  group('update', () {
    test(
      'sucesso -> ReviewDetailSaveSuccess preservando fotos/curtida',
      () async {
        when(
          () => repository.getById('rv-1'),
        ).thenAnswer((_) async => _review());
        when(
          () => repository.listPhotoUrls('rv-1'),
        ).thenAnswer((_) async => <String>['https://x/0.jpg']);
        when(
          () => repository.isLikedByUser('rv-1', 'user-1'),
        ).thenAnswer((_) async => true);
        when(
          () => repository.update(
            'rv-1',
            rating: 3.0,
            ambienceScore: any(named: 'ambienceScore'),
            serviceScore: any(named: 'serviceScore'),
            foodScore: any(named: 'foodScore'),
            costBenefitScore: any(named: 'costBenefitScore'),
            comment: 'Editado',
          ),
        ).thenAnswer((_) async => _review(rating: 3.0));

        final notifier = container.read(
          reviewDetailControllerProvider.notifier,
        );
        await notifier.load('rv-1', currentUserId: 'user-1');
        await notifier.update(
          'rv-1',
          rating: 3.0,
          ambienceScore: 3,
          serviceScore: 3,
          foodScore: 3,
          costBenefitScore: 3,
          comment: 'Editado',
        );

        final status = container.read(reviewDetailControllerProvider);
        expect(status, isA<ReviewDetailSaveSuccess>());
        final success = status as ReviewDetailSaveSuccess;
        expect(success.review.rating, 3.0);
        expect(success.photoUrls, ['https://x/0.jpg']);
        expect(success.likedByCurrentUser, isTrue);
      },
    );

    test('falha -> ReviewDetailError', () async {
      when(
        () => repository.update(
          'rv-1',
          rating: any(named: 'rating'),
          ambienceScore: any(named: 'ambienceScore'),
          serviceScore: any(named: 'serviceScore'),
          foodScore: any(named: 'foodScore'),
          costBenefitScore: any(named: 'costBenefitScore'),
          comment: any(named: 'comment'),
        ),
      ).thenThrow(const ReviewRepositoryException('Fora da janela de edição.'));

      await container
          .read(reviewDetailControllerProvider.notifier)
          .update(
            'rv-1',
            rating: 3.0,
            ambienceScore: 3,
            serviceScore: 3,
            foodScore: 3,
            costBenefitScore: 3,
            comment: 'Editado',
          );

      final status = container.read(reviewDetailControllerProvider);
      expect(status, isA<ReviewDetailError>());
      expect(
        (status as ReviewDetailError).message,
        'Fora da janela de edição.',
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

    test('descurte quando já curtido', () async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => true);
      when(() => repository.unlike('rv-1', 'user-1')).thenAnswer((_) async {});

      final notifier = container.read(reviewDetailControllerProvider.notifier);
      await notifier.load('rv-1', currentUserId: 'user-1');

      when(
        () => repository.getById('rv-1'),
      ).thenAnswer((_) async => _review(likesCount: 0));

      await notifier.toggleLike('rv-1', 'user-1');

      final status = container.read(reviewDetailControllerProvider);
      expect(status, isA<ReviewDetailSaveSuccess>());
      expect((status as ReviewDetailSaveSuccess).likedByCurrentUser, isFalse);
      verify(() => repository.unlike('rv-1', 'user-1')).called(1);
    });

    test('falha -> ReviewDetailError', () async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);
      when(
        () => repository.like('rv-1', 'user-1'),
      ).thenThrow(const ReviewRepositoryException('Não foi possível curtir.'));

      final notifier = container.read(reviewDetailControllerProvider.notifier);
      await notifier.load('rv-1', currentUserId: 'user-1');
      await notifier.toggleLike('rv-1', 'user-1');

      final status = container.read(reviewDetailControllerProvider);
      expect(status, isA<ReviewDetailError>());
      expect((status as ReviewDetailError).message, 'Não foi possível curtir.');
    });
  });

  group('addPhoto', () {
    test('sucesso adiciona e acumula fotos entre chamadas', () async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);
      when(
        () => repository.addPhoto(
          'rv-1',
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      ).thenAnswer((_) async => _review());

      final notifier = container.read(reviewDetailControllerProvider.notifier);
      await notifier.load('rv-1', currentUserId: 'user-1');

      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>['https://x/0.jpg']);
      await notifier.addPhoto(
        'rv-1',
        bytes: Uint8List(0),
        fileExtension: 'jpg',
      );

      final firstSave = container.read(reviewDetailControllerProvider);
      expect(firstSave, isA<ReviewDetailSaveSuccess>());
      expect((firstSave as ReviewDetailSaveSuccess).photoUrls, [
        'https://x/0.jpg',
      ]);

      // Segunda chamada parte de ReviewDetailSaveSuccess (não de
      // ReviewDetailLoaded) — exercita o outro ramo de `_currentDetails()`.
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>['https://x/0.jpg', 'https://x/1.jpg']);
      await notifier.addPhoto(
        'rv-1',
        bytes: Uint8List(0),
        fileExtension: 'jpg',
      );

      final secondSave = container.read(reviewDetailControllerProvider);
      expect(secondSave, isA<ReviewDetailSaveSuccess>());
      expect((secondSave as ReviewDetailSaveSuccess).photoUrls, [
        'https://x/0.jpg',
        'https://x/1.jpg',
      ]);
    });

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

    test('falha -> ReviewDetailError', () async {
      when(
        () => repository.addPhoto(
          'rv-1',
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      ).thenThrow(const ReviewRepositoryException('Falha no upload.'));

      await container
          .read(reviewDetailControllerProvider.notifier)
          .addPhoto('rv-1', bytes: Uint8List(0), fileExtension: 'jpg');

      final status = container.read(reviewDetailControllerProvider);
      expect(status, isA<ReviewDetailError>());
      expect((status as ReviewDetailError).message, 'Falha no upload.');
    });

    // RC-02: enquanto a foto sobe, o estado preserva review/fotos/curtida
    // em vez de cair para ReviewDetailSaving - evita que a tela vire um
    // spinner de tela cheia a cada foto adicionada.
    test('durante o upload -> ReviewDetailPhotoUploading preserva '
        'review/fotos/curtida', () async {
      when(() => repository.getById('rv-1')).thenAnswer((_) async => _review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>['https://x/0.jpg']);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => true);

      final notifier = container.read(reviewDetailControllerProvider.notifier);
      await notifier.load('rv-1', currentUserId: 'user-1');

      final completer = Completer<Review>();
      when(
        () => repository.addPhoto(
          'rv-1',
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      ).thenAnswer((_) => completer.future);

      final future = notifier.addPhoto(
        'rv-1',
        bytes: Uint8List(0),
        fileExtension: 'jpg',
      );

      final duringUpload = container.read(reviewDetailControllerProvider);
      expect(duringUpload, isA<ReviewDetailPhotoUploading>());
      final uploading = duringUpload as ReviewDetailPhotoUploading;
      expect(uploading.review.id, 'rv-1');
      expect(uploading.photoUrls, ['https://x/0.jpg']);
      expect(uploading.likedByCurrentUser, isTrue);

      completer.complete(_review());
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>['https://x/0.jpg', 'https://x/1.jpg']);
      await future;

      expect(
        container.read(reviewDetailControllerProvider),
        isA<ReviewDetailSaveSuccess>(),
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

    test('falha -> ReviewDetailError', () async {
      when(
        () => repository.delete('rv-1'),
      ).thenThrow(const ReviewRepositoryException('Não é o autor.'));

      await container
          .read(reviewDetailControllerProvider.notifier)
          .delete('rv-1');

      final status = container.read(reviewDetailControllerProvider);
      expect(status, isA<ReviewDetailError>());
      expect((status as ReviewDetailError).message, 'Não é o autor.');
    });

    // 2B.3 (P1): sucesso deve remover a review das duas listas que podem
    // exibi-la, sem exigir refresh manual do usuário.
    test('sucesso remove a review de ReviewsController e '
        'UserReviewsController já carregados (sem refetch)', () async {
      when(
        () => repository.listByRestaurant('r-1', page: 1, limit: 20),
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
      when(
        () => repository.listByUser('user-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [
            _review(id: 'rv-1'),
            _review(id: 'rv-3'),
          ],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(() => repository.delete('rv-1')).thenAnswer((_) async {});

      await container
          .read(reviewsControllerProvider.notifier)
          .loadForRestaurant('r-1');
      await container
          .read(userReviewsControllerProvider.notifier)
          .loadForUser('user-1');

      await container
          .read(reviewDetailControllerProvider.notifier)
          .delete('rv-1');

      final reviewsStatus =
          container.read(reviewsControllerProvider) as ReviewsLoaded;
      expect(reviewsStatus.result.items.map((r) => r.id), ['rv-2']);

      final userReviewsStatus =
          container.read(userReviewsControllerProvider) as ReviewsLoaded;
      expect(userReviewsStatus.result.items.map((r) => r.id), ['rv-3']);

      // Nenhum novo fetch - a remoção é local, não um refresh.
      verify(
        () => repository.listByRestaurant('r-1', page: 1, limit: 20),
      ).called(1);
      verify(
        () => repository.listByUser('user-1', page: 1, limit: 20),
      ).called(1);
    });

    test(
      'sucesso não quebra quando as listas ainda não foram carregadas',
      () async {
        when(() => repository.delete('rv-1')).thenAnswer((_) async {});

        await container
            .read(reviewDetailControllerProvider.notifier)
            .delete('rv-1');

        expect(
          container.read(reviewDetailControllerProvider),
          isA<ReviewDetailDeleted>(),
        );
        expect(
          container.read(reviewsControllerProvider),
          isA<ReviewsInitial>(),
        );
      },
    );
  });
}
