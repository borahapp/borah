import 'dart:typed_data';

import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/event_reviews/application/submit_event_review_controller.dart';
import 'package:app/features/event_reviews/data/event_review_repository_impl.dart';
import 'package:app/features/event_reviews/domain/event_review.dart';
import 'package:app/features/event_reviews/domain/event_review_repository.dart';
import 'package:app/features/event_reviews/presentation/states/submit_event_review_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventReviewRepository extends Mock implements EventReviewRepository {}

EventReview _review({String? photoPath, String? photoUrl}) {
  return EventReview(
    id: 'r-1',
    eventId: 'e-1',
    userId: 'user-1',
    foodScore: 5,
    serviceScore: 4,
    ambienceScore: 5,
    costBenefitScore: 4,
    overallScore: 5,
    comment: 'Muito bom!',
    fullName: 'Você',
    avatarUrl: null,
    photoPath: photoPath,
    photoUrl: photoUrl,
  );
}

void main() {
  late MockEventReviewRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockEventReviewRepository();
    container = ProviderContainer(
      overrides: [
        eventReviewRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue('user-1'),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é SubmitEventReviewInitial', () {
    expect(
      container.read(submitEventReviewControllerProvider),
      isA<SubmitEventReviewInitial>(),
    );
  });

  group('save (sem existingReviewId -> submit)', () {
    test('sucesso -> SubmitEventReviewSaveSuccess', () async {
      when(
        () => repository.submit(
          eventId: 'e-1',
          userId: 'user-1',
          foodScore: 5,
          serviceScore: 4,
          ambienceScore: 5,
          costBenefitScore: 4,
          overallScore: 5,
          comment: 'Muito bom!',
        ),
      ).thenAnswer((_) async => _review());

      await container
          .read(submitEventReviewControllerProvider.notifier)
          .save(
            eventId: 'e-1',
            foodScore: 5,
            serviceScore: 4,
            ambienceScore: 5,
            costBenefitScore: 4,
            overallScore: 5,
            comment: 'Muito bom!',
          );

      expect(
        container.read(submitEventReviewControllerProvider),
        isA<SubmitEventReviewSaveSuccess>(),
      );
      verifyNever(
        () => repository.update(
          reviewId: any(named: 'reviewId'),
          foodScore: any(named: 'foodScore'),
          serviceScore: any(named: 'serviceScore'),
          ambienceScore: any(named: 'ambienceScore'),
          costBenefitScore: any(named: 'costBenefitScore'),
          overallScore: any(named: 'overallScore'),
        ),
      );
    });

    test(
      'falha com EventReviewRepositoryException -> SubmitEventReviewError com a mensagem original',
      () async {
        when(
          () => repository.submit(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
            foodScore: any(named: 'foodScore'),
            serviceScore: any(named: 'serviceScore'),
            ambienceScore: any(named: 'ambienceScore'),
            costBenefitScore: any(named: 'costBenefitScore'),
            overallScore: any(named: 'overallScore'),
            comment: any(named: 'comment'),
          ),
        ).thenThrow(
          const EventReviewRepositoryException(
            'Você ainda não pode avaliar este rolê.',
          ),
        );

        await container
            .read(submitEventReviewControllerProvider.notifier)
            .save(
              eventId: 'e-1',
              foodScore: 5,
              serviceScore: 4,
              ambienceScore: 5,
              costBenefitScore: 4,
              overallScore: 5,
            );

        final status = container.read(submitEventReviewControllerProvider);
        expect(status, isA<SubmitEventReviewError>());
        expect(
          (status as SubmitEventReviewError).message,
          'Você ainda não pode avaliar este rolê.',
        );
      },
    );
  });

  group('save (com existingReviewId -> update)', () {
    test('sucesso -> chama update, nunca submit', () async {
      when(
        () => repository.update(
          reviewId: 'r-1',
          foodScore: 3,
          serviceScore: 4,
          ambienceScore: 5,
          costBenefitScore: 4,
          overallScore: 5,
          comment: null,
        ),
      ).thenAnswer((_) async => _review());

      await container
          .read(submitEventReviewControllerProvider.notifier)
          .save(
            eventId: 'e-1',
            existingReviewId: 'r-1',
            foodScore: 3,
            serviceScore: 4,
            ambienceScore: 5,
            costBenefitScore: 4,
            overallScore: 5,
          );

      expect(
        container.read(submitEventReviewControllerProvider),
        isA<SubmitEventReviewSaveSuccess>(),
      );
      verifyNever(
        () => repository.submit(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
          foodScore: any(named: 'foodScore'),
          serviceScore: any(named: 'serviceScore'),
          ambienceScore: any(named: 'ambienceScore'),
          costBenefitScore: any(named: 'costBenefitScore'),
          overallScore: any(named: 'overallScore'),
        ),
      );
    });
  });

  group('save com foto (FASE A2)', () {
    test('com photoBytes, anexa a foto após salvar a avaliação', () async {
      when(
        () => repository.submit(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
          foodScore: any(named: 'foodScore'),
          serviceScore: any(named: 'serviceScore'),
          ambienceScore: any(named: 'ambienceScore'),
          costBenefitScore: any(named: 'costBenefitScore'),
          overallScore: any(named: 'overallScore'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => _review());
      when(
        () => repository.attachPhoto(
          reviewId: 'r-1',
          bytes: any(named: 'bytes'),
          fileExtension: 'jpg',
          previousPath: null,
        ),
      ).thenAnswer(
        (_) async => _review(
          photoPath: 'r-1/photo.jpg',
          photoUrl: 'https://x/r-1/photo.jpg',
        ),
      );

      await container
          .read(submitEventReviewControllerProvider.notifier)
          .save(
            eventId: 'e-1',
            foodScore: 5,
            serviceScore: 4,
            ambienceScore: 5,
            costBenefitScore: 4,
            overallScore: 5,
            photoBytes: Uint8List(0),
            photoFileExtension: 'jpg',
          );

      final status = container.read(submitEventReviewControllerProvider);
      expect(status, isA<SubmitEventReviewSaveSuccess>());
      final success = status as SubmitEventReviewSaveSuccess;
      expect(success.photoWarning, isNull);
      expect(success.review.photoUrl, 'https://x/r-1/photo.jpg');
    });

    test(
      'falha ao anexar a foto não derruba o envio - salva com aviso',
      () async {
        when(
          () => repository.submit(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
            foodScore: any(named: 'foodScore'),
            serviceScore: any(named: 'serviceScore'),
            ambienceScore: any(named: 'ambienceScore'),
            costBenefitScore: any(named: 'costBenefitScore'),
            overallScore: any(named: 'overallScore'),
            comment: any(named: 'comment'),
          ),
        ).thenAnswer((_) async => _review());
        when(
          () => repository.attachPhoto(
            reviewId: any(named: 'reviewId'),
            bytes: any(named: 'bytes'),
            fileExtension: any(named: 'fileExtension'),
            previousPath: any(named: 'previousPath'),
          ),
        ).thenThrow(const EventReviewRepositoryException('Falha de rede.'));

        await container
            .read(submitEventReviewControllerProvider.notifier)
            .save(
              eventId: 'e-1',
              foodScore: 5,
              serviceScore: 4,
              ambienceScore: 5,
              costBenefitScore: 4,
              overallScore: 5,
              photoBytes: Uint8List(0),
              photoFileExtension: 'jpg',
            );

        final status = container.read(submitEventReviewControllerProvider);
        expect(status, isA<SubmitEventReviewSaveSuccess>());
        expect(
          (status as SubmitEventReviewSaveSuccess).photoWarning,
          'Avaliação salva, mas não foi possível enviar a foto.',
        );
      },
    );

    test(
      'com removePhoto e previousPhotoPath, remove a foto existente',
      () async {
        when(
          () => repository.update(
            reviewId: 'r-1',
            foodScore: 5,
            serviceScore: 4,
            ambienceScore: 5,
            costBenefitScore: 4,
            overallScore: 5,
            comment: null,
          ),
        ).thenAnswer((_) async => _review(photoPath: 'r-1/old.jpg'));
        when(
          () =>
              repository.removePhoto(reviewId: 'r-1', photoPath: 'r-1/old.jpg'),
        ).thenAnswer((_) async => _review());

        await container
            .read(submitEventReviewControllerProvider.notifier)
            .save(
              eventId: 'e-1',
              existingReviewId: 'r-1',
              foodScore: 5,
              serviceScore: 4,
              ambienceScore: 5,
              costBenefitScore: 4,
              overallScore: 5,
              removePhoto: true,
              previousPhotoPath: 'r-1/old.jpg',
            );

        final status = container.read(submitEventReviewControllerProvider);
        expect(status, isA<SubmitEventReviewSaveSuccess>());
        expect(
          (status as SubmitEventReviewSaveSuccess).review.photoPath,
          isNull,
        );
        verify(
          () =>
              repository.removePhoto(reviewId: 'r-1', photoPath: 'r-1/old.jpg'),
        ).called(1);
      },
    );

    test(
      'falha ao remover a foto não derruba o envio - salva com aviso',
      () async {
        when(
          () => repository.update(
            reviewId: 'r-1',
            foodScore: 5,
            serviceScore: 4,
            ambienceScore: 5,
            costBenefitScore: 4,
            overallScore: 5,
            comment: null,
          ),
        ).thenAnswer((_) async => _review(photoPath: 'r-1/old.jpg'));
        when(
          () =>
              repository.removePhoto(reviewId: 'r-1', photoPath: 'r-1/old.jpg'),
        ).thenThrow(const EventReviewRepositoryException('Falha de rede.'));

        await container
            .read(submitEventReviewControllerProvider.notifier)
            .save(
              eventId: 'e-1',
              existingReviewId: 'r-1',
              foodScore: 5,
              serviceScore: 4,
              ambienceScore: 5,
              costBenefitScore: 4,
              overallScore: 5,
              removePhoto: true,
              previousPhotoPath: 'r-1/old.jpg',
            );

        final status = container.read(submitEventReviewControllerProvider);
        expect(status, isA<SubmitEventReviewSaveSuccess>());
        expect(
          (status as SubmitEventReviewSaveSuccess).photoWarning,
          'Avaliação salva, mas não foi possível remover a foto.',
        );
        // A avaliação salva continua sendo a retornada por `update()`
        // (com `photoPath` antigo ainda presente) - a falha em
        // `removePhoto()` não é aplicada localmente ao resultado.
        expect(status.review.photoPath, 'r-1/old.jpg');
      },
    );
  });
}
