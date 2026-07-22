import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/qa_environment.dart';
import '../helpers/qa_restaurant_helper.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada C, cenário 1 (Listagem de restaurantes) — busca com
/// resultado. O caso de estado vazio está em `listing_empty_test.dart`
/// (arquivo separado - cada `integration_test` roda em seu próprio
/// processo, e dois testes de login real no mesmo arquivo
/// compartilhariam a mesma sessão do Supabase).
///
/// `RestaurantsController` não tem `loadNextPage()` (diferente de
/// Favoritos/Feed) e `RestaurantsSearchPage` não tem nenhum gatilho de
/// scroll infinito - **paginação não existe nesta tela hoje**, então não
/// há o que validar além do carregamento da primeira página (`page: 1`
/// default de `RestaurantSearchFilters`). Documentado aqui em vez de
/// simulado artificialmente.
///
/// "Tratamento de erro" também não é testado de ponta a ponta: não há
/// forma confiável de forçar uma falha real do backend saudável sem
/// manipular a rede - fora do escopo desta rodada.
///
/// Executar com:
/// flutter test integration_test/restaurants/listing_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  late QaRestaurantHelper restaurantHelper;
  String? createdUserId;
  String? createdRestaurantId;
  const password = 'SenhaForte123';

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
    userHelper = QaTestConfig.buildUserHelper();
    restaurantHelper = QaTestConfig.buildRestaurantHelper();
  });

  tearDown(() async {
    if (createdRestaurantId != null) {
      await restaurantHelper.deleteRestaurant(createdRestaurantId!);
      createdRestaurantId = null;
    }
    if (createdUserId != null) {
      await userHelper.deleteTestUser(createdUserId!);
      createdUserId = null;
    }
  });

  testWidgets('listagem carrega e encontra um restaurante pelo nome buscado', (
    tester,
  ) async {
    final email =
        'qa-listing-${DateTime.now().millisecondsSinceEpoch}@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );
    final restaurantName =
        'QA Listing Test ${DateTime.now().millisecondsSinceEpoch}';
    createdRestaurantId = await restaurantHelper.createRestaurant(
      createdBy: createdUserId!,
      name: restaurantName,
      category: 'Bar',
      city: 'São Paulo',
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: email, password: password);

    await tester.tap(find.text('Ver restaurantes'));
    await pumpUntil(
      tester,
      () => find.text('Restaurantes').evaluate().isNotEmpty,
      timeoutMessage:
          'A tela de Restaurantes não abriu a tempo (carregamento inicial).',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Buscar por nome'),
      restaurantName,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // `find.text(restaurantName)` sozinho seria ambíguo aqui: o campo
    // "Buscar por nome" ainda contém o mesmo texto digitado, então
    // casaria tanto com o `EditableText` da busca quanto com o `Text`
    // do item da lista (achado real durante a Rodada C, ao tentar
    // navegar a partir do item de lista em outro cenário).
    // `widgetWithText(ListTile, ...)` identifica o item da lista sem
    // ambiguidade.
    await pumpUntil(
      tester,
      () => find.widgetWithText(ListTile, restaurantName).evaluate().isNotEmpty,
      timeoutMessage: 'A busca não retornou o restaurante recém-criado.',
    );

    expect(find.widgetWithText(ListTile, restaurantName), findsOneWidget);
  });
}
