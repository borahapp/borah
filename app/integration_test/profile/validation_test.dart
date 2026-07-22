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

/// QA-03, Rodada E, cenário 4 (Validação).
///
/// **Limitação conhecida (achado na ETAPA 0, não corrigida nesta
/// rodada):** o único campo obrigatório de `EditProfilePage` é "Nome"
/// (`validateRequired`, `core/validators/app_validators.dart`). Não
/// existe nenhum limite de tamanho - nem validador no cliente, nem
/// constraint `CHECK` na migration `20260718180242_create_profiles.sql`
/// (colunas `text` sem limite). Por isso este cenário valida apenas o
/// campo obrigatório e a proteção contra envio inválido (form não
/// submetido enquanto inválido) - "limites de tamanho" não tem o que
/// validar, por não existir em nenhuma camada da aplicação.
///
/// Executar com:
/// flutter test integration_test/profile/validation_test.dart \
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

  testWidgets('formulário de edição exige nome preenchido e não envia dados '
      'inválidos', (tester) async {
    final email =
        'qa-profile-validation-${DateTime.now().millisecondsSinceEpoch}'
        '@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: email, password: password);
    await openProfile(tester);

    await tester.tap(find.text('Editar perfil'));
    await pumpUntil(
      tester,
      () => find.widgetWithText(TextFormField, 'Nome').evaluate().isNotEmpty,
      timeoutMessage: 'A tela de Editar Perfil não abriu a tempo.',
    );

    // Usuário recém-criado tem `full_name = ''` (trigger
    // `handle_new_user`) - o campo "Nome" já chega vazio, sem precisar
    // de limpeza manual.
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    // Ainda em Editar Perfil - o envio inválido não deveria navegar.
    expect(find.widgetWithText(FilledButton, 'Salvar'), findsOneWidget);

    final profile = await userHelper.fetchProfile(createdUserId!);
    expect(
      profile!['full_name'],
      '',
      reason: 'O envio inválido não deveria ter alterado o perfil no banco.',
    );
  });
}
