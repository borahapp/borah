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

/// QA-03, Rodada B, cenário 4 (Persistência). Reiniciar o processo do
/// app de verdade não é viável dentro de um único arquivo de
/// `integration_test`; a técnica usada aqui - desmontar a árvore de
/// widgets inteira (`ProviderScope`/`AuthController`/`GoRouter` novos) e
/// remontá-la sem chamar `Supabase.initialize()` de novo - simula um
/// reinício fielmente: a sessão persistida pelo `supabase_flutter` fica
/// em armazenamento local no dispositivo (fora da árvore de widgets), e
/// `SplashPage.restoreSession()` é chamado do zero na nova árvore,
/// exatamente como aconteceria em uma reabertura real do app.
///
/// Executar com:
/// flutter test integration_test/authentication/persistence_test.dart \
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

  testWidgets('sessão é restaurada corretamente após reiniciar o app', (
    tester,
  ) async {
    final email =
        'qa-persistence-${DateTime.now().millisecondsSinceEpoch}@borah.test';
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
      () => find
          .widgetWithText(NavigationDestination, 'Restaurantes')
          .evaluate()
          .isNotEmpty,
      maxAttempts: 100,
      timeoutMessage:
          'O login (pré-condição do teste) não navegou para a Home a tempo.',
    );

    final sessionBeforeRestart = Supabase.instance.client.auth.currentSession;
    expect(sessionBeforeRestart, isNotNull);

    // Simula o reinício: desmonta a árvore inteira e remonta do zero,
    // sem chamar Supabase.initialize() novamente.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));

    await pumpUntil(
      tester,
      () =>
          find
              .widgetWithText(NavigationDestination, 'Restaurantes')
              .evaluate()
              .isNotEmpty ||
          find.text('Entrar').evaluate().isNotEmpty,
      maxAttempts: 100,
      timeoutMessage:
          'A Splash não terminou de decidir para onde navegar após o '
          '"reinício" simulado.',
    );

    expect(
      find.widgetWithText(NavigationDestination, 'Restaurantes'),
      findsOneWidget,
      reason:
          'A Splash deveria ter restaurado a sessão automaticamente e '
          'navegado direto para a Home, sem pedir login novamente.',
    );
    expect(
      Supabase.instance.client.auth.currentSession?.user.id,
      createdUserId,
      reason: 'A sessão restaurada deveria ser do mesmo usuário.',
    );
  });
}
