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
/// O cadastro tem dois desfechos válidos e mutuamente exclusivos,
/// dependendo da configuração "Confirm email" do projeto Supabase (fora
/// do controle deste teste - `borah-qa` está com ela **desabilitada**
/// hoje, ver EX-10 §7):
/// - **ON** (confirmação exigida): `signUp()` não cria sessão -
///   `AuthController` define `EmailVerificationPending` e o app navega
///   para `/email-verification`.
/// - **OFF** (sem confirmação, cenário atual do `borah-qa`): `signUp()`
///   já retorna com sessão ativa - `AuthController` define
///   `Authenticated` diretamente (correção da condição de corrida entre
///   o retorno de `signUp()` e `onAuthStateChange`) e o app navega para
///   `/home`.
///
/// O teste espera por qualquer um dos dois desfechos e então valida o
/// que de fato aconteceu - nunca aceita silenciosamente um terceiro
/// estado (ex.: uma tela de erro): se nenhum dos dois aparecer dentro do
/// tempo limite, ou se algo além dos dois aparecer, o teste falha com
/// uma mensagem clara.
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

  testWidgets('cadastro cria o usuário, o profile automático e navega '
      'corretamente conforme a configuração de confirmação de e-mail', (
    tester,
  ) async {
    final email =
        'qa-signup-${DateTime.now().millisecondsSinceEpoch}@mailinator.com';

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await pumpUntil(tester, () => find.text('Entrar').evaluate().isNotEmpty);

    await tester.tap(find.text('Criar conta'));
    // `context.push('/signup')` empilha a rota sobre a LoginPage - durante
    // a animação de transição, as duas telas ficam montadas ao mesmo
    // tempo, e ambas têm um campo rotulado "E-mail". Esperar só o campo
    // "Nome" (exclusivo do SignupPage) aparecer não é suficiente; é
    // preciso também esperar o botão "Entrar" (exclusivo da LoginPage)
    // desaparecer, garantindo que a transição terminou por completo antes
    // de interagir com o formulário.
    await pumpUntil(
      tester,
      () =>
          find.widgetWithText(TextFormField, 'Nome').evaluate().isNotEmpty &&
          find.text('Entrar').evaluate().isEmpty,
      timeoutMessage:
          'A transição de LoginPage para SignupPage não terminou a tempo.',
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

    // Chamada de rede real ao Supabase QA - aguarda um dos dois
    // desfechos válidos (ver doc do arquivo). Não usa `pumpAndSettle`
    // pelo mesmo motivo documentado em `app_smoke_test.dart`.
    bool reachedEmailVerification() =>
        find.text('Voltar para o login').evaluate().isNotEmpty;
    // RC-04E: `/home` (HomeShellPage) abre na aba "Restaurantes" por
    // padrão - `NavigationDestination` evita ambiguidade com o título
    // "Restaurantes" da própria `AppTopBar` da tela.
    bool reachedHome() => find
        .widgetWithText(NavigationDestination, 'Restaurantes')
        .evaluate()
        .isNotEmpty;

    await pumpUntil(
      tester,
      () => reachedEmailVerification() || reachedHome(),
      maxAttempts: 100,
      timeoutMessage:
          'O cadastro não navegou nem para /email-verification nem para '
          '/home a tempo. Causa provável: erro real retornado pelo '
          'Supabase (ex.: "over_email_send_rate_limit" - já observado '
          'neste projeto QA ao repetir cadastros em curto intervalo, '
          'ver EX-10 §7).',
    );

    if (reachedEmailVerification()) {
      // Confirm email = ON: confirmação pendente, sem sessão ainda.
      expect(find.textContaining('Confirme seu e-mail'), findsOneWidget);
      expect(
        Supabase.instance.client.auth.currentSession,
        isNull,
        reason:
            'Não deveria haver sessão enquanto a confirmação de e-mail '
            'estiver pendente.',
      );
    } else if (reachedHome()) {
      // Confirm email = OFF (cenário atual do borah-qa): sessão já
      // criada, navegação direta para a Home.
      expect(
        find.widgetWithText(NavigationDestination, 'Restaurantes'),
        findsOneWidget,
      );
      expect(
        Supabase.instance.client.auth.currentSession,
        isNotNull,
        reason:
            'Uma sessão real deveria existir quando o cadastro navega '
            'direto para a Home.',
      );
    } else {
      fail(
        'Estado inesperado após o cadastro: nem a tela de confirmação '
        'nem a Home foram encontradas.',
      );
    }

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
