import 'package:app/design_system/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('mostra posição, nome, subtítulo e valor à direita', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const RankingCard(
          position: 4,
          name: 'Cantina do Bairro',
          subtitle: 'São Paulo',
          trailingLabel: '4.5 (12)',
        ),
      ),
    );

    expect(find.text('Cantina do Bairro'), findsOneWidget);
    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('4.5 (12)'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets(
    'auditoria de família de cards: espaço entre nome e subtítulo, mesmo padrão de GroupCard/EventCard/RestaurantCard',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RankingCard(
            position: 4,
            name: 'Cantina do Bairro',
            subtitle: 'São Paulo',
          ),
        ),
      );

      final nameBottom = tester.getBottomLeft(find.text('Cantina do Bairro'));
      final subtitleTop = tester.getTopLeft(find.text('São Paulo'));
      expect(subtitleTop.dy, greaterThan(nameBottom.dy));
    },
  );

  testWidgets('posições 1 a 3 mostram a medalha em vez do número', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const RankingCard(position: 1, name: 'Cantina do Bairro')),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('toque dispara onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        RankingCard(
          position: 4,
          name: 'Cantina do Bairro',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Cantina do Bairro'));
    expect(tapped, isTrue);
  });
}
