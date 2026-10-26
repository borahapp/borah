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
      organizerId: 'u-organizer',
      scheduledAt: DateTime(2026, 1, 1),
      status: status,
      restaurantName: 'Cantina da Vila',
    ),
    attendances: const [],
  );
}

EventReview _review({
  String id = 'r-1',
  String userId = 'user-2',
  String fullName = 'Amigo do grupo',
  String? photoUrl,
  String? comment,
  double foodScore = 5,
  double serviceScore = 5,
  double ambienceScore = 5,
  double costBenefitScore = 5,
  double overallScore = 5,
}) {
  return EventReview(
    id: id,
    eventId: 'e-1',
    userId: userId,
    foodScore: foodScore,
    serviceScore: serviceScore,
    ambienceScore: ambienceScore,
    costBenefitScore: costBenefitScore,
    overallScore: overallScore,
    comment: comment,
    fullName: fullName,
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
    expect(find.text('Álbum do rolê'), findsNothing);
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
      // RC-03 F39: a mesma foto agora também aparece na grade "Álbum do
      // rolê" além da miniatura inline - 2 `Image` no total, não 1.
      expect(find.text('Álbum do rolê'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
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

  group('FASE 04 - critérios individuais da avaliação coletiva', () {
    testWidgets(
      'mostra os 5 critérios com rótulo e nota correta, cada um em texto '
      'próprio (nunca separado do rótulo)',
      (tester) async {
        when(() => reviewRepository.listByEvent('e-1')).thenAnswer(
          (_) async => [
            _review(
              foodScore: 4,
              serviceScore: 3,
              ambienceScore: 5,
              costBenefitScore: 2,
              overallScore: 4,
            ),
          ],
        );

        await tester.pumpWidget(_wrap(eventRepository, reviewRepository));
        await tester.pumpAndSettle();

        expect(find.text('Comida: 4.0'), findsOneWidget);
        expect(find.text('Atendimento: 3.0'), findsOneWidget);
        expect(find.text('Ambiente: 5.0'), findsOneWidget);
        expect(find.text('Custo-benefício: 2.0'), findsOneWidget);
        expect(find.text('Experiência geral: 4.0'), findsOneWidget);
        // Média geral (trailing/AppBadge) continua visível e correta -
        // (4+3+5+2+4)/5 = 3.6 - inalterada por esta fase.
        expect(find.text('3.6'), findsOneWidget);
      },
    );

    testWidgets(
      'duas avaliações mostram, cada uma, os critérios do seu próprio '
      'avaliador, sem misturar valores',
      (tester) async {
        when(() => reviewRepository.listByEvent('e-1')).thenAnswer(
          (_) async => [
            _review(
              id: 'r-1',
              userId: 'user-2',
              fullName: 'Ana',
              foodScore: 5,
              serviceScore: 5,
              ambienceScore: 5,
              costBenefitScore: 5,
              overallScore: 5,
            ),
            _review(
              id: 'r-2',
              userId: 'user-3',
              fullName: 'Bruno',
              foodScore: 1,
              serviceScore: 2,
              ambienceScore: 1,
              costBenefitScore: 2,
              overallScore: 1,
            ),
          ],
        );

        await tester.pumpWidget(_wrap(eventRepository, reviewRepository));
        await tester.pumpAndSettle();

        expect(find.text('Ana'), findsOneWidget);
        expect(find.text('Bruno'), findsOneWidget);
        // Ana: todos os 5 critérios em 5.0.
        expect(find.text('Comida: 5.0'), findsOneWidget);
        expect(find.text('Atendimento: 5.0'), findsOneWidget);
        expect(find.text('Ambiente: 5.0'), findsOneWidget);
        expect(find.text('Custo-benefício: 5.0'), findsOneWidget);
        expect(find.text('Experiência geral: 5.0'), findsOneWidget);
        // Bruno: valores bem diferentes, nunca confundidos com os de Ana.
        expect(find.text('Comida: 1.0'), findsOneWidget);
        expect(find.text('Atendimento: 2.0'), findsOneWidget);
        expect(find.text('Ambiente: 1.0'), findsOneWidget);
        expect(find.text('Custo-benefício: 2.0'), findsOneWidget);
        expect(find.text('Experiência geral: 1.0'), findsOneWidget);
      },
    );

    testWidgets(
      'avaliação com comentário e foto continua mostrando os dois, além '
      'dos 5 critérios',
      (tester) async {
        when(() => reviewRepository.listByEvent('e-1')).thenAnswer(
          (_) async => [
            _review(
              comment: 'Lugar ótimo!',
              photoUrl: 'https://x/e-1/photo.jpg',
            ),
          ],
        );

        await tester.pumpWidget(_wrap(eventRepository, reviewRepository));
        await tester.pumpAndSettle();
        while (tester.takeException() != null) {}

        expect(find.text('Comida: 5.0'), findsOneWidget);
        expect(find.text('Lugar ótimo!'), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(2));
      },
    );
  });
}
