import 'package:app/design_system/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('mostra nome, contagem de integrantes e próximo rolê', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const GroupCard(
          name: 'Galera do Rolê',
          memberCount: 5,
          nextEventLabel: 'Próximo rolê: 12/08',
        ),
      ),
    );

    expect(find.text('Galera do Rolê'), findsOneWidget);
    expect(find.text('5 integrantes'), findsOneWidget);
    expect(find.text('Próximo rolê: 12/08'), findsOneWidget);
  });

  testWidgets('1 integrante usa singular', (tester) async {
    await tester.pumpWidget(
      _wrap(const GroupCard(name: 'Grupo Novo', memberCount: 1)),
    );

    expect(find.text('1 integrante'), findsOneWidget);
  });

  testWidgets('sem próximo rolê mostra "Sem rolês ainda"', (tester) async {
    await tester.pumpWidget(
      _wrap(const GroupCard(name: 'Grupo Novo', memberCount: 2)),
    );

    expect(find.text('Sem rolês ainda'), findsOneWidget);
  });

  testWidgets('sem foto, usa accentColor como fundo do avatar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GroupCard(
          name: 'Grupo Colorido',
          memberCount: 3,
          accentColor: Colors.red,
        ),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundColor, Colors.red);
  });

  testWidgets('toque dispara onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        GroupCard(
          name: 'Galera do Rolê',
          memberCount: 5,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Galera do Rolê'));
    expect(tapped, isTrue);
  });
}
