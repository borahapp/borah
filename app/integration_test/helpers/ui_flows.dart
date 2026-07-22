import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_helpers.dart';

/// Fluxos de UI reutilizados entre os testes de Restaurantes/Avaliações
/// (QA-03, Rodada C) - evita duplicar os mesmos passos de login e
/// navegação em cada arquivo de cenário.

/// Assume que o app já está na tela de Login (Splash já resolvida).
Future<void> signInViaUi(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await pumpUntil(
    tester,
    () => find.text('Entrar').evaluate().isNotEmpty,
    timeoutMessage: 'A tela de Login não apareceu a tempo.',
  );

  await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));

  await pumpUntil(
    tester,
    () => find.text('Ver perfil').evaluate().isNotEmpty,
    maxAttempts: 100,
    timeoutMessage: 'O login não navegou para a Home a tempo.',
  );
}

/// A partir da Home, busca o restaurante pelo nome (distintivo o
/// suficiente para não colidir com outros dados do ambiente QA) e abre
/// a tela de Detalhes.
Future<void> openRestaurantByName(
  WidgetTester tester,
  String restaurantName,
) async {
  await tester.tap(find.text('Ver restaurantes'));
  await pumpUntil(
    tester,
    () => find.text('Restaurantes').evaluate().isNotEmpty,
    timeoutMessage: 'A tela de Restaurantes não abriu a tempo.',
  );

  await tester.enterText(
    find.widgetWithText(TextFormField, 'Buscar por nome'),
    restaurantName,
  );
  await tester.testTextInput.receiveAction(TextInputAction.done);

  await pumpUntil(
    tester,
    () => find.widgetWithText(ListTile, restaurantName).evaluate().isNotEmpty,
    timeoutMessage: 'A busca não retornou o restaurante "$restaurantName".',
  );

  // Em execução real (emulador), o teclado virtual pode continuar
  // aberto após o "done" do campo de busca e interceptar o toque
  // seguinte no item da lista - remover o foco e aguardar a animação de
  // fechamento evita esse problema (achado real durante a Rodada C).
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();

  // `find.text(restaurantName)` sozinho é ambíguo aqui: o campo "Buscar
  // por nome" ainda contém o mesmo texto digitado, então casaria tanto
  // com o `EditableText` da busca quanto com o `Text` do item da lista
  // (achado real durante a Rodada C). `widgetWithText(ListTile, ...)`
  // identifica o item da lista sem ambiguidade.
  await tester.tap(find.widgetWithText(ListTile, restaurantName));
  await pumpUntil(
    tester,
    () => find.text('Ver avaliações').evaluate().isNotEmpty,
    timeoutMessage: 'A tela de Detalhes do restaurante não abriu a tempo.',
  );
}

/// A partir da Home, abre a tela de Favoritos (QA-03, Rodada D).
Future<void> openFavorites(WidgetTester tester) async {
  await tester.tap(find.text('Ver favoritos'));
  await pumpUntil(
    tester,
    () => find.text('Favoritos').evaluate().isNotEmpty,
    timeoutMessage: 'A tela de Favoritos não abriu a tempo.',
  );
}

/// A partir da Home, abre a tela de Feed (QA-03, Rodada D).
Future<void> openFeed(WidgetTester tester) async {
  await tester.tap(find.text('Ver feed'));
  await pumpUntil(
    tester,
    () => find.text('Feed').evaluate().isNotEmpty,
    timeoutMessage: 'A tela de Feed não abriu a tempo.',
  );
}
