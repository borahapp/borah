import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/presentation/widgets/review_summary_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Review _review({
  String? authorFullName,
  String? restaurantName,
  String? comment = 'Ótimo!',
  double? ambienceScore,
  double? serviceScore,
  double? foodScore,
  double? costBenefitScore,
}) {
  return Review(
    id: 'rv-1',
    restaurantId: 'r-1',
    userId: 'user-1',
    rating: 4.5,
    ambienceScore: ambienceScore,
    serviceScore: serviceScore,
    foodScore: foodScore,
    costBenefitScore: costBenefitScore,
    comment: comment,
    likesCount: 0,
    photosCount: 0,
    createdAt: DateTime(2026, 3, 7),
    updatedAt: DateTime(2026, 3, 7),
    authorFullName: authorFullName,
    restaurantName: restaurantName,
  );
}

Widget _wrap(Review review) {
  return MaterialApp(
    home: Scaffold(body: ReviewSummaryTile(review: review)),
  );
}

void main() {
  testWidgets('mostra autor, restaurante, data e comentário quando '
      'resolvidos (2B.3 - P2/P3)', (tester) async {
    await tester.pumpWidget(
      _wrap(_review(authorFullName: 'Bruno Costa', restaurantName: 'Outback')),
    );

    expect(find.textContaining('Bruno Costa'), findsOneWidget);
    expect(find.textContaining('Outback'), findsOneWidget);
    expect(find.text('07/03/2026'), findsOneWidget);
    expect(find.text('Ótimo!'), findsOneWidget);
  });

  testWidgets('autor/restaurante ausentes não quebram o widget - só a data '
      'e o comentário aparecem', (tester) async {
    await tester.pumpWidget(_wrap(_review()));

    expect(tester.takeException(), isNull);
    expect(find.text('07/03/2026'), findsOneWidget);
    expect(find.text('Ótimo!'), findsOneWidget);
  });

  testWidgets('sem comentário não quebra o widget', (tester) async {
    await tester.pumpWidget(_wrap(_review(comment: null)));

    expect(tester.takeException(), isNull);
    expect(find.text('07/03/2026'), findsOneWidget);
  });

  group('critérios individuais (FASE 07)', () {
    testWidgets('avaliação completa (4 critérios) mostra o detalhamento', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _review(
            ambienceScore: 4.0,
            serviceScore: 5.0,
            foodScore: 4.5,
            costBenefitScore: 3.5,
          ),
        ),
      );

      expect(find.text('Comida: 4.5'), findsOneWidget);
      expect(find.text('Atendimento: 5.0'), findsOneWidget);
      expect(find.text('Ambiente: 4.0'), findsOneWidget);
      expect(find.text('Custo-benefício: 3.5'), findsOneWidget);
    });

    testWidgets('avaliação antiga sem critérios não mostra o detalhamento', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_review()));

      expect(find.textContaining('Comida:'), findsNothing);
      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets(
      'avaliação parcialmente preenchida é tratada como sem critérios',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_review(foodScore: 4.0, serviceScore: 4.0)),
        );

        expect(find.textContaining('Comida:'), findsNothing);
        expect(find.textContaining('Atendimento:'), findsNothing);
        expect(find.text('4.5'), findsOneWidget);
      },
    );
  });
}
