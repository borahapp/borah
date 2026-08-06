import 'package:app/design_system/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('mostra nome e legenda', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RestaurantHeader(name: 'Cantina da Vila', subtitle: '12/08/2026'),
      ),
    );

    expect(find.text('Cantina da Vila'), findsOneWidget);
    expect(find.text('12/08/2026'), findsOneWidget);
  });

  testWidgets('sem legenda, mostra só o nome', (tester) async {
    await tester.pumpWidget(_wrap(const RestaurantHeader(name: 'Madero')));

    expect(find.text('Madero'), findsOneWidget);
  });

  testWidgets('sem foto, usa o ícone de restaurante como fallback', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const RestaurantHeader(name: 'Madero')));

    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });
}
