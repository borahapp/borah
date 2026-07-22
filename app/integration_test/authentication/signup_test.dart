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

/// QA-03, Rodada B, cenário 1 (Cadastro de usuário). Usa o formulário
/// real de `SignupPage` - diferente dos demais cenários desta rodada,
/// que criam usuários via `QaTestUserHelper` (Admin API) porque o próprio
/// fluxo de cadastro é o que está sendo validado aqui.
///
/// O e-mail usa o domínio `mailinator.com` (inboxes públicas, uso comum
/// e seguro para este propósito) - domínios reservados de teste
/// (`.test`, `example.com`) são rejeitados pela validação de e-mail do
/// GoTrue, achado confirmado na Rodada 0 e reconfirmado antes desta
/// implementação.
///
/// Executar com:
/// flutter test integration_test/authentication/signup_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  String? createdUserId;

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

  testWidgets('cadastro cria o usuário, o profile automático e navega para a '
      'confirmação de e-mail', (tester) async {
    final email =
        'qa-signup-${DateTime.now().millisecondsSinceEpoch}@mailinator.com';

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await pumpUntil(tester, () => find.text('Entrar').evaluate().isNotEmpty);

    await tester.tap(find.text('Criar conta'));
    await pumpUntil(
      tester,
      () => find.widgetWithText(TextFormField, 'Nome').evaluate().isNotEmpty,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'QA Signup Test',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'SenhaForte123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));

    // Chamada de rede real ao Supabase QA - aguarda a navegação para
    // /email-verification.
    await pumpUntil(
      tester,
      () => find.text('Voltar para o login').evaluate().isNotEmpty,
      maxAttempts: 100,
      timeoutMessage:
          'O cadastro não navegou para /email-verification a tempo. '
          'Causa provável: erro real retornado pelo Supabase (ex.: '
          '"over_email_send_rate_limit" - já observado neste projeto '
          'QA ao repetir cadastros em curto intervalo, ver EX-10 §7).',
    );

    expect(
      find.textContaining('Confirme seu e-mail'),
      findsOneWidget,
      reason: 'Deveria navegar para a tela de confirmação de e-mail.',
    );

    final user = await userHelper.findUserByEmail(email);
    expect(
      user,
      isNotNull,
      reason: 'O usuário deveria existir em auth.users após o cadastro.',
    );
    createdUserId = user!['id'] as String;

    final profile = await userHelper.fetchProfile(createdUserId!);
    expect(
      profile,
      isNotNull,
      reason:
          'O trigger handle_new_user() deveria ter criado o profile '
          'automaticamente.',
    );
  });
}
