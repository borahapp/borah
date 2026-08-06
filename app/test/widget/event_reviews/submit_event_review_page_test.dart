import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/event_reviews/data/event_review_repository_impl.dart';
import 'package:app/features/event_reviews/domain/event_review.dart';
import 'package:app/features/event_reviews/domain/event_review_repository.dart';
import 'package:app/features/event_reviews/presentation/pages/submit_event_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockEventReviewRepository extends Mock implements EventReviewRepository {}

Widget _wrap(
  MockEventReviewRepository repository, {
  String? restaurantName,
  DateTime? scheduledAt,
  String? restaurantCoverImage,
  EventReview? existingReview,
}) {
  // A tela real só é alcançada via `context.push` a partir de
  // `event_detail_page.dart` - nunca como raiz da navegação. Uma rota
  // anterior de verdade é necessária aqui para `context.pop()` (chamado
  // no sucesso do envio) ter para onde voltar, mesmo padrão de
  // `create_event_page_test.dart` (stub de tela anterior).
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/review'),
            child: const Text('Abrir avaliação'),
          ),
        ),
      ),
      GoRoute(
        path: '/review',
        builder: (_, _) => SubmitEventReviewPage(
          eventId: 'e-1',
          restaurantName: restaurantName,
          scheduledAt: scheduledAt,
          restaurantCoverImage: restaurantCoverImage,
          existingReview: existingReview,
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      eventReviewRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpAndOpen(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Abrir avaliação'));
  await tester.pumpAndSettle();
}

Future<void> _rate(WidgetTester tester, String label, int stars) async {
  final row = find.ancestor(
    of: find.text(label),
    matching: find.byType(Column),
  );
  final starIcons = find.descendant(
    of: row.first,
    matching: find.byIcon(Icons.star_outline_rounded),
  );
  await tester.tap(starIcons.at(stars - 1));
}

Future<void> _rateAllCriteria(WidgetTester tester, {int stars = 4}) async {
  for (final label in [
    'Ambiente',
    'Atendimento',
    'Comida',
    'Custo-benefício',
    'Experiência geral',
  ]) {
    await _rate(tester, label, stars);
    await tester.pump();
  }
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final finder = find.widgetWithText(FilledButton, 'Enviar avaliação');
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

void main() {
  late MockEventReviewRepository repository;

  setUp(() {
    repository = MockEventReviewRepository();
  });

  testWidgets('mostra os 5 critérios na ordem cronológica da visita', (
    tester,
  ) async {
    await _pumpAndOpen(tester, _wrap(repository));

    final labels = [
      'Ambiente',
      'Atendimento',
      'Comida',
      'Custo-benefício',
      'Experiência geral',
    ];
    var lastOffset = -1.0;
    for (final label in labels) {
      final offset = tester.getTopLeft(find.text(label)).dy;
      expect(offset, greaterThan(lastOffset));
      lastOffset = offset;
    }
  });

  testWidgets('com contexto informado, mostra nome e data do restaurante', (
    tester,
  ) async {
    await _pumpAndOpen(
      tester,
      _wrap(
        repository,
        restaurantName: 'Cantina da Vila',
        scheduledAt: DateTime(2026, 8, 12),
      ),
    );

    expect(find.text('Cantina da Vila'), findsOneWidget);
    expect(find.text('12/08/2026'), findsOneWidget);
  });

  testWidgets('sem contexto informado, não mostra o cabeçalho', (tester) async {
    await _pumpAndOpen(tester, _wrap(repository));

    expect(find.byIcon(Icons.restaurant), findsNothing);
  });

  testWidgets('progresso mostra "0 de 5" inicialmente e atualiza a cada nota', (
    tester,
  ) async {
    await _pumpAndOpen(tester, _wrap(repository));

    expect(find.text('0 de 5 critérios avaliados'), findsOneWidget);

    await _rate(tester, 'Ambiente', 3);
    await tester.pump();

    expect(find.text('1 de 5 critérios avaliados'), findsOneWidget);
  });

  testWidgets(
    'enviar sem preencher todos os critérios mostra erro de validação',
    (tester) async {
      await _pumpAndOpen(tester, _wrap(repository));

      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Escolha uma nota.'), findsWidgets);
      verifyNever(
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
      );
    },
  );

  testWidgets(
    'preenchendo os 5 critérios e enviando, chama o repositório e mostra confirmação',
    (tester) async {
      when(
        () => repository.submit(
          eventId: 'e-1',
          userId: 'user-1',
          foodScore: any(named: 'foodScore'),
          serviceScore: any(named: 'serviceScore'),
          ambienceScore: any(named: 'ambienceScore'),
          costBenefitScore: any(named: 'costBenefitScore'),
          overallScore: any(named: 'overallScore'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer(
        (_) async => const EventReview(
          id: 'r-1',
          eventId: 'e-1',
          userId: 'user-1',
          foodScore: 4,
          serviceScore: 4,
          ambienceScore: 4,
          costBenefitScore: 4,
          overallScore: 4,
          comment: null,
          fullName: 'Você',
          avatarUrl: null,
        ),
      );

      await _pumpAndOpen(tester, _wrap(repository));

      await _rateAllCriteria(tester);
      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      verify(
        () => repository.submit(
          eventId: 'e-1',
          userId: 'user-1',
          foodScore: 4,
          serviceScore: 4,
          ambienceScore: 4,
          costBenefitScore: 4,
          overallScore: 4,
          comment: null,
        ),
      ).called(1);
      expect(
        find.text('Sua nota já atualizou o ranking do grupo.'),
        findsOneWidget,
      );
      // Confirma que a tela realmente fechou (voltou para a rota
      // anterior) - não só que o snackbar apareceu.
      expect(find.text('Abrir avaliação'), findsOneWidget);
    },
  );

  testWidgets(
    'modo edição pré-preenche as estrelas com a avaliação existente',
    (tester) async {
      await _pumpAndOpen(
        tester,
        _wrap(
          repository,
          existingReview: const EventReview(
            id: 'r-1',
            eventId: 'e-1',
            userId: 'user-1',
            foodScore: 5,
            serviceScore: 3,
            ambienceScore: 4,
            costBenefitScore: 2,
            overallScore: 5,
            comment: 'Muito bom!',
            fullName: 'Você',
            avatarUrl: null,
          ),
        ),
      );

      expect(find.widgetWithText(AppBar, 'Editar avaliação'), findsOneWidget);
      expect(find.text('5 de 5 critérios avaliados'), findsOneWidget);
      expect(find.text('Muito bom!'), findsOneWidget);
    },
  );

  testWidgets('erro do repositório mostra snackbar com a mensagem', (
    tester,
  ) async {
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
      const EventReviewRepositoryException('Não foi possível avaliar.'),
    );

    await _pumpAndOpen(tester, _wrap(repository));

    await _rateAllCriteria(tester);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível avaliar.'), findsOneWidget);
  });
}
