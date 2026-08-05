import 'package:app/design_system/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('mostra os rótulos das abas e o conteúdo da 1ª aba', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AppTabs(
          tabs: [
            AppTabItem(label: 'Ranking', child: Text('Conteúdo do Ranking')),
            AppTabItem(
              label: 'Estatísticas',
              child: Text('Conteúdo de Estatísticas'),
            ),
            AppTabItem(label: 'Memórias', child: Text('Conteúdo de Memórias')),
          ],
        ),
      ),
    );

    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Estatísticas'), findsOneWidget);
    expect(find.text('Memórias'), findsOneWidget);
    expect(find.text('Conteúdo do Ranking'), findsOneWidget);
  });

  testWidgets('initialIndex abre diretamente na aba informada', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppTabs(
          initialIndex: 2,
          tabs: [
            AppTabItem(label: 'Ranking', child: Text('Conteúdo do Ranking')),
            AppTabItem(
              label: 'Estatísticas',
              child: Text('Conteúdo de Estatísticas'),
            ),
            AppTabItem(label: 'Memórias', child: Text('Conteúdo de Memórias')),
          ],
        ),
      ),
    );

    expect(find.text('Conteúdo de Memórias'), findsOneWidget);
  });

  testWidgets('tocar em outra aba troca o conteúdo exibido', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppTabs(
          tabs: [
            AppTabItem(label: 'Ranking', child: Text('Conteúdo do Ranking')),
            AppTabItem(
              label: 'Estatísticas',
              child: Text('Conteúdo de Estatísticas'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Estatísticas'));
    await tester.pumpAndSettle();

    expect(find.text('Conteúdo de Estatísticas'), findsOneWidget);
  });
}
