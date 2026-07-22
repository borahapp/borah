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

/// QA-03, Rodada E, cenário 2 (Atualização do Perfil). Dirige o
/// formulário real de `EditProfilePage` - é o próprio fluxo de edição
/// que está sendo validado.
///
/// Executar com:
/// flutter test integration_test/profile/update_test.dart \
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

  testWidgets('atualizar perfil altera nome e biografia, persiste no banco e '
      'reflete imediatamente na interface', (tester) async {
    final email =
        'qa-profile-update-${DateTime.now().millisecondsSinceEpoch}'
        '@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );
    final newName =
        'QA Profile Updated ${DateTime.now().millisecondsSinceEpoch}';
    const newBio = 'Biografia editada (QA-03).';

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

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), newName);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Biografia'),
      newBio,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));

    await pumpUntil(
      tester,
      () => find.text(newName).evaluate().isNotEmpty,
      maxAttempts: 100,
      timeoutMessage: 'Não voltou ao Perfil com os dados atualizados.',
    );

    expect(find.text(newName), findsOneWidget);
    expect(find.text(newBio), findsOneWidget);

    final profile = await userHelper.fetchProfile(createdUserId!);
    expect(profile, isNotNull);
    expect(profile!['full_name'], newName);
    expect(profile['bio'], newBio);
  });
}
