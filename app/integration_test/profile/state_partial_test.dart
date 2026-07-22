import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/qa_environment.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada E, cenário 5 (Estados) - perfil parcialmente
/// preenchido. Arquivo separado de `state_empty_test.dart` (isolamento
/// de processo/sessão).
///
/// Apenas `bio` é preenchida diretamente via PostgREST (precondição);
/// `full_name` permanece `''` (trigger `handle_new_user`) e
/// `city`/`state` permanecem nulos - a intenção é confirmar que cada
/// campo é exibido/ocultado de forma independente, não por um único
/// estado "vazio"/"preenchido" compartilhado.
///
/// Executar com:
/// flutter test integration_test/profile/state_partial_test.dart \
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

  testWidgets(
    'perfil parcialmente preenchido mostra apenas os campos definidos '
    'independentemente uns dos outros',
    (tester) async {
      final email =
          'qa-profile-partial-${DateTime.now().millisecondsSinceEpoch}'
          '@borah.test';
      createdUserId = await userHelper.createTestUser(
        email: email,
        password: password,
      );
      const bio = 'Só a bio está preenchida (QA-03).';
      await userHelper.updateProfileFields(createdUserId!, {'bio': bio});

      await initializeSupabase();
      await tester.pumpWidget(const ProviderScope(child: BorahApp()));
      await signInViaUi(tester, email: email, password: password);
      await openProfile(tester);

      // Nome ainda vazio (fallback), mas a bio já preenchida aparece -
      // cada campo é avaliado de forma independente pela tela.
      expect(find.text('Sem nome'), findsOneWidget);
      expect(find.text(bio), findsOneWidget);

      final profile = await userHelper.fetchProfile(createdUserId!);
      expect(profile, isNotNull);
      expect(profile!['full_name'], '');
      expect(profile['bio'], bio);
      expect(profile['city'], isNull);
      expect(profile['state'], isNull);
    },
  );
}
