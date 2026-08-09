import 'package:app/features/reviews/application/review_detail_controller.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/presentation/pages/edit_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

Review _review({
  String id = 'rv-1',
  double rating = 4,
  double? ambienceScore = 4,
  double? serviceScore = 3,
  double? foodScore = 5,
  double? costBenefitScore = 4,
  String? comment = 'Muito bom!',
}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: 'user-1',
    rating: rating,
    ambienceScore: ambienceScore,
    serviceScore: serviceScore,
    foodScore: foodScore,
    costBenefitScore: costBenefitScore,
    comment: comment,
    likesCount: 0,
    photosCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Future<ProviderContainer> _loadedContainer(
  MockReviewRepository repository, {
  Review? review,
}) async {
  when(
    () => repository.getById('rv-1'),
  ).thenAnswer((_) async => review ?? _review());
  when(
    () => repository.listPhotoUrls('rv-1'),
  ).thenAnswer((_) async => <String>[]);
  when(
    () => repository.isLikedByUser('rv-1', 'user-1'),
  ).thenAnswer((_) async => false);

  final container = ProviderContainer(
    overrides: [reviewRepositoryProvider.overrideWithValue(repository)],
  );
  await container
      .read(reviewDetailControllerProvider.notifier)
      .load('rv-1', currentUserId: 'user-1');
  return container;
}

/// Rota anterior real é necessária para `context.pop()` (chamado no
/// sucesso do salvamento) ter para onde voltar - mesmo padrão de
/// `submit_event_review_page_test.dart`.
Widget _wrap(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/edit'),
            child: const Text('Abrir edição'),
          ),
        ),
      ),
      GoRoute(
        path: '/edit',
        builder: (_, _) => const EditReviewPage(reviewId: 'rv-1'),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpAndOpen(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Abrir edição'));
  await tester.pumpAndSettle();
}

/// Toca na N-ésima estrela do critério `label`, independente de já estar
/// preenchida ou não (diferente do helper de `submit_event_review_page_test.dart`,
/// que só funciona partindo de 0 estrelas - aqui a avaliação já chega
/// pré-preenchida da API mockada).
Future<void> _rate(WidgetTester tester, String label, int stars) async {
  final row = find.ancestor(
    of: find.text(label),
    matching: find.byType(Column),
  );
  final starButtons = find.descendant(
    of: row.first,
    matching: find.byType(IconButton),
  );
  await tester.tap(starButtons.at(stars - 1));
}

void main() {
  late MockReviewRepository repository;

  setUp(() {
    repository = MockReviewRepository();
  });

  testWidgets('pré-preenche os 5 critérios com a avaliação existente', (
    tester,
  ) async {
    final container = await _loadedContainer(repository);
    addTearDown(container.dispose);

    await _pumpAndOpen(tester, _wrap(container));

    expect(find.text('5 de 5 critérios avaliados'), findsOneWidget);
    expect(find.text('Muito bom!'), findsOneWidget);
  });

  testWidgets('avaliação legada sem critérios pré-preenche só a nota geral', (
    tester,
  ) async {
    final container = await _loadedContainer(
      repository,
      review: _review(
        ambienceScore: null,
        serviceScore: null,
        foodScore: null,
        costBenefitScore: null,
      ),
    );
    addTearDown(container.dispose);

    await _pumpAndOpen(tester, _wrap(container));

    expect(find.text('1 de 5 critérios avaliados'), findsOneWidget);
  });

  testWidgets('salvar envia os 5 critérios atualizados', (tester) async {
    final container = await _loadedContainer(repository);
    addTearDown(container.dispose);

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
    ).thenAnswer((_) async => _review(rating: 5));

    await _pumpAndOpen(tester, _wrap(container));

    await _rate(tester, 'Experiência geral', 5);
    await tester.pump();

    final finder = find.widgetWithText(FilledButton, 'Salvar');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();

    verify(
      () => repository.update(
        'rv-1',
        rating: 5,
        ambienceScore: any(named: 'ambienceScore'),
        serviceScore: any(named: 'serviceScore'),
        foodScore: any(named: 'foodScore'),
        costBenefitScore: any(named: 'costBenefitScore'),
        comment: any(named: 'comment'),
      ),
    ).called(1);
  });

  testWidgets('erro ao salvar exibe snackbar com a mensagem', (tester) async {
    final container = await _loadedContainer(repository);
    addTearDown(container.dispose);

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

    await _pumpAndOpen(tester, _wrap(container));

    final finder = find.widgetWithText(FilledButton, 'Salvar');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();

    expect(find.text('Fora da janela de edição.'), findsOneWidget);
  });
}
