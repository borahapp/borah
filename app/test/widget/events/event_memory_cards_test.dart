import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/presentation/widgets/event_memory_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Event _event({
  String id = 'e-1',
  String restaurantId = 'r-1',
  String restaurantName = 'Cantina da Vila',
  String organizerId = 'u-1',
  double? averageRating,
}) {
  return Event(
    id: id,
    groupId: 'g-1',
    restaurantId: restaurantId,
    organizerId: organizerId,
    scheduledAt: DateTime(2026, 1, 1),
    status: 'completed',
    restaurantName: restaurantName,
    averageRating: averageRating,
  );
}

Widget _wrap(List<Event> realized) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) =>
            Column(children: EventMemoryCards.build(context, realized)),
      ),
    ),
  );
}

void main() {
  group('Quem mais escolheu (FASE B, Entrega 3)', () {
    testWidgets('organizador com mais rolês determina a contagem exibida', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap([
          _event(id: 'e-1', organizerId: 'u-1'),
          _event(id: 'e-2', organizerId: 'u-1'),
          _event(id: 'e-3', organizerId: 'u-2'),
        ]),
      );

      expect(find.text('Quem mais escolheu'), findsOneWidget);
      expect(find.text('pela mesma pessoa'), findsOneWidget);
      // "Mais visitado" também mostra "3 rolês" aqui (mesmo restaurante
      // em todos) - "2 rolês" só pode vir do organizador.
      expect(find.text('2 rolês'), findsOneWidget);
    });

    testWidgets(
      'empate entre organizadores mostra a contagem máxima, sem lançar',
      (tester) async {
        await tester.pumpWidget(
          _wrap([
            _event(id: 'e-1', organizerId: 'u-1'),
            _event(id: 'e-2', organizerId: 'u-2'),
            _event(id: 'e-3', organizerId: 'u-3'),
          ]),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Quem mais escolheu'), findsOneWidget);
        // Todo mundo empatado em 1 - o valor exibido é o máximo (1), não
        // uma pessoa escolhida entre os empatados (não há identidade
        // exibida, então não há "quem ganhou o desempate" para testar).
        expect(find.text('1 rolê'), findsOneWidget);
      },
    );

    testWidgets('um único rolê usa singular nos dois cards que se aplicam', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap([_event(id: 'e-1', organizerId: 'u-1')]));

      // "Mais visitado" e "Quem mais escolheu" mostram "1 rolê" cada -
      // esperado, não uma colisão: com 1 único rolê realizado, as duas
      // métricas coincidem trivialmente.
      expect(find.text('1 rolê'), findsNWidgets(2));
    });

    testWidgets('mesmo organizador em todos os rolês soma o total', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap([
          _event(id: 'e-1', restaurantId: 'r-1', organizerId: 'u-1'),
          _event(id: 'e-2', restaurantId: 'r-2', organizerId: 'u-1'),
          _event(id: 'e-3', restaurantId: 'r-3', organizerId: 'u-1'),
        ]),
      );

      expect(find.text('Quem mais escolheu'), findsOneWidget);
      expect(find.text('3 rolês'), findsOneWidget);
    });

    testWidgets('lista vazia não renderiza nenhum card, sem lançar', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const []));

      expect(tester.takeException(), isNull);
      expect(find.text('Quem mais escolheu'), findsNothing);
      expect(find.text('Mais visitado'), findsNothing);
      expect(find.text('Campeão'), findsNothing);
    });
  });

  group('cards existentes permanecem inalterados', () {
    testWidgets(
      'Mais visitado e Campeão continuam corretos com o novo card presente',
      (tester) async {
        await tester.pumpWidget(
          _wrap([
            _event(
              id: 'e-1',
              restaurantId: 'r-1',
              restaurantName: 'Cantina da Vila',
              organizerId: 'u-1',
              averageRating: 4.0,
            ),
            _event(
              id: 'e-2',
              restaurantId: 'r-1',
              restaurantName: 'Cantina da Vila',
              organizerId: 'u-1',
              averageRating: 4.0,
            ),
            _event(
              id: 'e-3',
              restaurantId: 'r-1',
              restaurantName: 'Cantina da Vila',
              organizerId: 'u-2',
              averageRating: 4.0,
            ),
            _event(
              id: 'e-4',
              restaurantId: 'r-2',
              restaurantName: 'Sushi Kaze',
              organizerId: 'u-3',
              averageRating: 5.0,
            ),
          ]),
        );

        expect(find.text('Mais visitado'), findsOneWidget);
        expect(find.text('Cantina da Vila'), findsOneWidget);
        expect(find.text('3 rolês'), findsOneWidget);
        expect(find.text('Campeão'), findsOneWidget);
        expect(find.text('Sushi Kaze'), findsOneWidget);
        expect(find.text('5.0 ⭐'), findsOneWidget);
        expect(find.text('Quem mais escolheu'), findsOneWidget);
        expect(find.text('2 rolês'), findsOneWidget);
      },
    );

    testWidgets('sem nenhum rolê avaliado, Campeão não aparece', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap([_event(id: 'e-1', averageRating: null)]));

      expect(find.text('Campeão'), findsNothing);
      expect(find.text('Mais visitado'), findsOneWidget);
      expect(find.text('Quem mais escolheu'), findsOneWidget);
    });
  });
}
