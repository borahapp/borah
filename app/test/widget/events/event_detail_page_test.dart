import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/event_reviews/data/event_review_repository_impl.dart';
import 'package:app/features/event_reviews/domain/event_review.dart';
import 'package:app/features/event_reviews/domain/event_review_repository.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_details.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/events/presentation/pages/event_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockEventReviewRepository extends Mock implements EventReviewRepository {}

EventDetails _details({String status = 'scheduled'}) {
  return EventDetails(
    event: Event(
      id: 'e-1',
      groupId: 'g-1',
      restaurantId: 'r-1',
      scheduledAt: DateTime(2026, 1, 1),
      status: status,
      restaurantName: 'Cantina da Vila',
    ),
    attendances: const [],
  );
}

EventReview _review({String id = 'r-1', String? photoUrl}) {
  return EventReview(
    id: id,
    eventId: 'e-1',
    userId: 'user-2',
    foodScore: 5,
    serviceScore: 5,
    ambienceScore: 5,
    costBenefitScore: 5,
    overallScore: 5,
    comment: null,
    fullName: 'Amigo do grupo',
    avatarUrl: null,
    photoUrl: photoUrl,
  );
}

Widget _wrap(
  MockEventRepository eventRepository,
  MockEventReviewRepository reviewRepository,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const EventDetailPage(eventId: 'e-1', groupId: 'g-1'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(eventRepository),
      eventReviewRepositoryProvider.overrideWithValue(reviewRepository),
      // `null` evita precisar mockar `isGroupAdmin` (só chamado quando
      // há usuário autenticado) - irrelevante para o que estes testes
      // verificam (miniatura de foto na lista de avaliações).
      currentUserIdProvider.overrideWithValue(null),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockEventRepository eventRepository;
  late MockEventReviewRepository reviewRepository;

  setUp(() {
    eventRepository = MockEventRepository();
    reviewRepository = MockEventReviewRepository();
    when(
      () => eventRepository.getById('e-1'),
    ).thenAnswer((_) async => _details());
  });

  testWidgets('avaliação sem foto não mostra nenhuma miniatura', (
    tester,
  ) async {
    when(
      () => reviewRepository.listByEvent('e-1'),
    ).thenAnswer((_) async => [_review()]);

    await tester.pumpWidget(_wrap(eventRepository, reviewRepository));
    await tester.pumpAndSettle();

    expect(find.text('Amigo do grupo'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'avaliação com foto mostra a miniatura ao lado da nota, sem esconder o avatar',
    (tester) async {
      when(
        () => reviewRepository.listByEvent('e-1'),
      ).thenAnswer((_) async => [_review(photoUrl: 'https://x/e-1/photo.jpg')]);

      await tester.pumpWidget(_wrap(eventRepository, reviewRepository));
      await tester.pumpAndSettle();
      // `Image.network` sem servidor real no ambiente de teste -
      // mesmo padrão de drenagem de exceção já usado em
      // `submit_event_review_page_test.dart`.
      while (tester.takeException() != null) {}

      // Quem avaliou continua sendo a informação primária da linha -
      // a foto é um acréscimo, nunca uma substituição.
      expect(find.text('Amigo do grupo'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets('sem nenhuma avaliação, mostra o estado vazio da seção', (
    tester,
  ) async {
    when(() => reviewRepository.listByEvent('e-1')).thenAnswer((_) async => []);

    await tester.pumpWidget(_wrap(eventRepository, reviewRepository));
    await tester.pumpAndSettle();

    expect(find.text('Ninguém avaliou este rolê ainda.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
