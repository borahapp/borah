import 'package:app/design_system/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('mostra restaurante, data/hora e confirmados', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EventCard(
          restaurantName: 'Cantina do Bairro',
          dateTimeLabel: '12/08 às 20h',
          confirmedCount: 3,
          status: 'scheduled',
          statusLabel: 'Agendado',
        ),
      ),
    );

    expect(find.text('Cantina do Bairro'), findsOneWidget);
    expect(find.text('12/08 às 20h'), findsOneWidget);
    expect(find.text('3 confirmados'), findsOneWidget);
  });

  testWidgets('1 confirmado usa singular', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EventCard(
          restaurantName: 'Cantina do Bairro',
          dateTimeLabel: '12/08 às 20h',
          confirmedCount: 1,
          status: 'scheduled',
          statusLabel: 'Agendado',
        ),
      ),
    );

    expect(find.text('1 confirmado'), findsOneWidget);
  });

  testWidgets('status "scheduled" não mostra selo', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EventCard(
          restaurantName: 'Cantina do Bairro',
          dateTimeLabel: '12/08 às 20h',
          confirmedCount: 3,
          status: 'scheduled',
          statusLabel: 'Agendado',
        ),
      ),
    );

    expect(find.text('Agendado'), findsNothing);
  });

  testWidgets('status "completed" mostra o selo com o rótulo', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EventCard(
          restaurantName: 'Cantina do Bairro',
          dateTimeLabel: '12/08 às 20h',
          confirmedCount: 3,
          status: 'completed',
          statusLabel: 'Realizado',
        ),
      ),
    );

    expect(find.text('Realizado'), findsOneWidget);
  });

  testWidgets('sem foto do restaurante, mostra o ícone padrão', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EventCard(
          restaurantName: 'Cantina do Bairro',
          dateTimeLabel: '12/08 às 20h',
          confirmedCount: 3,
          status: 'scheduled',
          statusLabel: 'Agendado',
        ),
      ),
    );

    expect(find.byIcon(Icons.restaurant), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('com foto do restaurante, mostra a imagem em vez do ícone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const EventCard(
          restaurantName: 'Cantina do Bairro',
          dateTimeLabel: '12/08 às 20h',
          confirmedCount: 3,
          status: 'scheduled',
          statusLabel: 'Agendado',
          restaurantPhotoUrl: 'https://x/restaurant.jpg',
        ),
      ),
    );
    while (tester.takeException() != null) {}

    expect(find.byIcon(Icons.restaurant), findsNothing);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('toque dispara onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EventCard(
          restaurantName: 'Cantina do Bairro',
          dateTimeLabel: '12/08 às 20h',
          confirmedCount: 3,
          status: 'scheduled',
          statusLabel: 'Agendado',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Cantina do Bairro'));
    expect(tapped, isTrue);
  });
}
