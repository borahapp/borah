import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/qa_environment.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada C, cenário 1 (Listagem de restaurantes) — estado vazio.
///
/// Em arquivo separado de `listing_test.dart` porque cada arquivo de
/// `integration_test` roda em seu próprio processo/app - dois
/// `testWidgets` no mesmo arquivo compartilhariam a mesma sessão real do
/// Supabase (a sessão do primeiro login "vazaria" para o segundo teste,
/// que encontraria a Home já autenticada em vez do Login). Mesmo padrão
/// de isolamento já usado na Rodada B (Autenticação).
///
/// Executar com:
/// flutter test integration_test/restaurants/listing_empty_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  String? createdUserId;
  const password = 'SenhaForte123';

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
    userHelper = QaTestConfig.buildUserHelper();
  });

  tearDown(() async {
    if (createdUserId != null) {
      await userHelper.deleteTestUser(createdUserId!);
      createdUserId = null;
    }
  });

  testWidgets('estado vazio mostra mensagem para busca sem resultados', (
    tester,
  ) async {
    final email =
        'qa-listing-empty-${DateTime.now().millisecondsSinceEpoch}@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: email, password: password);

    await tester.tap(find.text('Ver restaurantes'));
    await pumpUntil(
      tester,
      () => find.text('Restaurantes').evaluate().isNotEmpty,
      timeoutMessage: 'A tela de Restaurantes não abriu a tempo.',
    );

    final noResultsQuery =
        'qa-no-results-${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Buscar por nome'),
      noResultsQuery,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await pumpUntil(
      tester,
      () => find.text('Nenhum restaurante encontrado.').evaluate().isNotEmpty,
      timeoutMessage: 'O estado vazio não apareceu a tempo.',
    );

    expect(find.text('Nenhum restaurante encontrado.'), findsOneWidget);
  });
}
