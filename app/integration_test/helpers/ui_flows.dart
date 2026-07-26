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

  // RC-04E: `/home` passou a ser o `HomeShellPage` (navegação inferior
  // com a aba "Restaurantes" selecionada por padrão) - `NavigationDestination`
  // identifica a aba sem ambiguidade com o título "Restaurantes" da
  // própria `AppTopBar` da tela (ambos usariam `find.text` senão).
  await pumpUntil(
    tester,
    () => find
        .widgetWithText(NavigationDestination, 'Restaurantes')
        .evaluate()
        .isNotEmpty,
    maxAttempts: 100,
    timeoutMessage: 'O login não navegou para a Home a tempo.',
  );
}

/// A partir da Home (aba "Restaurantes", selecionada por padrão), busca
/// o restaurante pelo nome (distintivo o suficiente para não colidir com
/// outros dados do ambiente QA) e abre a tela de Detalhes.
Future<void> openRestaurantByName(
  WidgetTester tester,
  String restaurantName,
) async {
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

/// A partir da Home, troca para a aba "Favoritos" do `HomeShellPage`
/// (RC-04E). `NavigationDestination` evita ambiguidade com o título
/// "Favoritos" da própria `AppTopBar` da tela (`IndexedStack` mantém as
/// duas abas montadas - só a selecionada fica onstage).
Future<void> openFavorites(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Favoritos'));
  await tester.pumpAndSettle();
}

/// A partir da Home, troca para a aba "Feed" do `HomeShellPage` (RC-04E).
Future<void> openFeed(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Feed'));
  await tester.pumpAndSettle();
}

/// A partir da Home, troca para a aba "Perfil" do `HomeShellPage`
/// (RC-04E). Espera pelo botão "Editar perfil" (só aparece em
/// `ProfileLoaded`/`ProfileUpdating`/`ProfileUpdateSuccess`) em vez do
/// ícone de configurações, que fica no `AppBar` de `ProfilePage` fora do
/// `switch` de estado - ele já aparece durante `ProfileLoading`, antes
/// dos dados do perfil chegarem (achado real durante a Rodada E).
Future<void> openProfile(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
  await pumpUntil(
    tester,
    () => find.text('Editar perfil').evaluate().isNotEmpty,
    timeoutMessage: 'A tela de Perfil não carregou os dados a tempo.',
  );
}

/// Efetua logout a partir de `ProfilePage` (único lugar do app com a
/// ação "Sair", via `SettingsPage`) - mesma técnica já validada em
/// `authentication/logout_test.dart` (Rodada B). Assume que o app já
/// está em `ProfilePage`.
Future<void> logoutViaUi(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await pumpUntil(
    tester,
    () => find.text('Sair').evaluate().isNotEmpty,
    timeoutMessage: 'A tela de Configurações não abriu a tempo.',
  );

  await tester.tap(find.text('Sair'));
  await pumpUntil(
    tester,
    () => find.text('Entrar').evaluate().isNotEmpty,
    maxAttempts: 100,
    timeoutMessage: 'O logout não retornou ao Login a tempo.',
  );
}
