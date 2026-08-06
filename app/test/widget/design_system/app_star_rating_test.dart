import 'package:app/design_system/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {GlobalKey<FormState>? formKey}) {
  return MaterialApp(
    home: Scaffold(
      body: Form(key: formKey ?? GlobalKey<FormState>(), child: child),
    ),
  );
}

void main() {
  testWidgets('mostra 5 estrelas vazias por padrão', (tester) async {
    await tester.pumpWidget(
      _wrap(AppStarRating(label: 'Comida', onChanged: (_) {})),
    );

    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
  });

  testWidgets('tocar na 3ª estrela preenche as 3 primeiras e chama onChanged', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      _wrap(
        AppStarRating(label: 'Comida', onChanged: (value) => selected = value),
      ),
    );

    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(2));
    await tester.pump();

    expect(selected, 3);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
  });

  testWidgets('initialValue preenche as estrelas correspondentes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(AppStarRating(label: 'Comida', initialValue: 4, onChanged: (_) {})),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(1));
  });

  testWidgets('caption é exibida quando informada', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppStarRating(
          label: 'Experiência geral',
          caption: 'Sua nota geral para o rolê',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Sua nota geral para o rolê'), findsOneWidget);
  });

  testWidgets('sem nota escolhida, validate() falha com mensagem padrão', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _wrap(
        AppStarRating(label: 'Comida', onChanged: (_) {}),
        formKey: formKey,
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Escolha uma nota.'), findsOneWidget);
  });

  testWidgets('após escolher uma nota, validate() passa', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _wrap(
        AppStarRating(label: 'Comida', onChanged: (_) {}),
        formKey: formKey,
      ),
    );

    await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
    await tester.pump();

    expect(formKey.currentState!.validate(), isTrue);
  });
}
