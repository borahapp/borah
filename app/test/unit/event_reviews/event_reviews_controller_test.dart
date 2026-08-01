import 'package:app/features/event_reviews/application/event_reviews_controller.dart';
import 'package:app/features/event_reviews/data/event_review_repository_impl.dart';
import 'package:app/features/event_reviews/domain/event_review.dart';
import 'package:app/features/event_reviews/domain/event_review_repository.dart';
import 'package:app/features/event_reviews/presentation/states/event_reviews_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventReviewRepository extends Mock implements EventReviewRepository {}

EventReview _review({String userId = 'u-1'}) {
  return EventReview(
    id: 'r-1',
    eventId: 'e-1',
    userId: userId,
    foodScore: 5,
    serviceScore: 4,
    ambienceScore: 5,
    costBenefitScore: 4,
    overallScore: 5,
    comment: 'Muito bom!',
    fullName: 'Ana Silva',
    avatarUrl: null,
  );
}

void main() {
  late MockEventReviewRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockEventReviewRepository();
    container = ProviderContainer(
      overrides: [eventReviewRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é EventReviewsInitial', () {
    expect(
      container.read(eventReviewsControllerProvider),
      isA<EventReviewsInitial>(),
    );
  });

  group('load', () {
    test('sucesso -> EventReviewsLoaded', () async {
      when(
        () => repository.listByEvent('e-1'),
      ).thenAnswer((_) async => [_review()]);

      await container.read(eventReviewsControllerProvider.notifier).load('e-1');

      final status = container.read(eventReviewsControllerProvider);
      expect(status, isA<EventReviewsLoaded>());
      expect((status as EventReviewsLoaded).reviews, hasLength(1));
    });

    test(
      'lista vazia -> EventReviewsEmpty (mesmo padrão de UserReviewsController)',
      () async {
        when(() => repository.listByEvent('e-1')).thenAnswer((_) async => []);

        await container
            .read(eventReviewsControllerProvider.notifier)
            .load('e-1');

        expect(
          container.read(eventReviewsControllerProvider),
          isA<EventReviewsEmpty>(),
        );
      },
    );

    test(
      'falha com EventReviewRepositoryException -> EventReviewsError com a mensagem original',
      () async {
        when(() => repository.listByEvent('e-1')).thenThrow(
          const EventReviewRepositoryException('Não foi possível carregar.'),
        );

        await container
            .read(eventReviewsControllerProvider.notifier)
            .load('e-1');

        final status = container.read(eventReviewsControllerProvider);
        expect(status, isA<EventReviewsError>());
        expect(
          (status as EventReviewsError).message,
          'Não foi possível carregar.',
        );
      },
    );

    test(
      'falha inesperada -> EventReviewsError com mensagem genérica',
      () async {
        when(
          () => repository.listByEvent('e-1'),
        ).thenThrow(Exception('erro de rede'));

        await container
            .read(eventReviewsControllerProvider.notifier)
            .load('e-1');

        final status = container.read(eventReviewsControllerProvider);
        expect(status, isA<EventReviewsError>());
        expect(
          (status as EventReviewsError).message,
          'Não foi possível carregar as avaliações.',
        );
      },
    );
  });
}
