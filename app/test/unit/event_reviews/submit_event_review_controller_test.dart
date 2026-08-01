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

EventReview _review() {
  return const EventReview(
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
  );
}

void main() {
  late MockEventReviewRepository repository;
  late ProviderContainer container;

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
}
