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

/// QA-03, Rodada B, cenário 2 (Login). O usuário é criado via
/// `QaTestUserHelper` (Admin API, já confirmado - `email_confirm: true`),
/// não pelo formulário de cadastro, pois o que está sendo validado aqui
/// é o fluxo de autenticação, não o de cadastro.
///
/// Executar com:
/// flutter test integration_test/authentication/login_test.dart \
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

  testWidgets('login autentica com sucesso, cria sessão e navega para Home', (
    tester,
  ) async {
    final email =
        'qa-login-${DateTime.now().millisecondsSinceEpoch}@borah.test';
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

    // Chamada de rede real ao Supabase QA - aguarda o redirect global do
    // GoRouter (Authenticated + rota de auth -> /home).
    await pumpUntil(
      tester,
      () => find
          .widgetWithText(NavigationDestination, 'Restaurantes')
          .evaluate()
          .isNotEmpty,
      maxAttempts: 100,
      timeoutMessage: 'O login não navegou para a Home a tempo.',
    );

    expect(
      find.widgetWithText(NavigationDestination, 'Restaurantes'),
      findsOneWidget,
      reason: 'Login bem-sucedido deveria navegar para a Home.',
    );
    expect(
      Supabase.instance.client.auth.currentSession,
      isNotNull,
      reason: 'Uma sessão real deveria ter sido criada após o login.',
    );
    expect(
      Supabase.instance.client.auth.currentSession!.user.id,
      createdUserId,
    );
  });
}
