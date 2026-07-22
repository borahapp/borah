import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/qa_environment.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';

/// QA-03, Rodada B, cenário 3 (Logout). Usuário criado via
/// `QaTestUserHelper`; o teste faz login pela UI (pré-condição real, não
/// atalho de estado) e então navega até "Configurações" (`SettingsPage`,
/// único lugar do app com a ação "Sair") para encerrar a sessão.
///
/// Executar com:
/// flutter test integration_test/authentication/logout_test.dart \
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

  testWidgets('logout encerra a sessão e retorna ao Login', (tester) async {
    final email =
        'qa-logout-${DateTime.now().millisecondsSinceEpoch}@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await pumpUntil(tester, () => find.text('Entrar').evaluate().isNotEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      password,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await pumpUntil(
      tester,
      () => find.text('Ver perfil').evaluate().isNotEmpty,
      maxAttempts: 100,
      timeoutMessage:
          'O login (pré-condição do teste) não navegou para a Home a tempo.',
    );

    await tester.tap(find.text('Ver perfil'));
    await pumpUntil(
      tester,
      () => find.byIcon(Icons.settings).evaluate().isNotEmpty,
      timeoutMessage: 'Não chegou ao ProfilePage após tocar em "Ver perfil".',
    );

    await tester.tap(find.byIcon(Icons.settings));
    await pumpUntil(
      tester,
      () => find.text('Sair').evaluate().isNotEmpty,
      timeoutMessage:
          'Não chegou ao SettingsPage após tocar no ícone de configurações.',
    );

    await tester.tap(find.text('Sair'));
    await pumpUntil(
      tester,
      () => find.text('Entrar').evaluate().isNotEmpty,
      maxAttempts: 100,
      timeoutMessage: 'O logout não retornou ao Login a tempo.',
    );

    expect(
      find.text('Entrar'),
      findsOneWidget,
      reason: 'Logout deveria retornar à tela de Login.',
    );
    expect(
      Supabase.instance.client.auth.currentSession,
      isNull,
      reason: 'A sessão deveria ter sido encerrada após o logout.',
    );
  });
}
