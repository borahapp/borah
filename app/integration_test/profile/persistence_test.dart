import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/qa_environment.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada E, cenário 3 (Persistência). Os campos são preenchidos
/// diretamente via PostgREST (precondição - "atualizar perfil" já é
/// validado em `update_test.dart`); o que está sendo validado aqui é
/// que a informação sobrevive a um ciclo real de logout/login, não o
/// próprio fluxo de edição.
///
/// Executar com:
/// flutter test integration_test/profile/persistence_test.dart \
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
    'informações do perfil permanecem salvas e consistentes com o banco '
    'após logout e login novamente',
    (tester) async {
      final email =
          'qa-profile-persist-${DateTime.now().millisecondsSinceEpoch}'
          '@borah.test';
      createdUserId = await userHelper.createTestUser(
        email: email,
        password: password,
      );
      final fullName =
          'QA Profile Persist ${DateTime.now().millisecondsSinceEpoch}';
      const bio = 'Bio persistente (QA-03).';
      await userHelper.updateProfileFields(createdUserId!, {
        'full_name': fullName,
        'bio': bio,
      });

      await initializeSupabase();
      await tester.pumpWidget(const ProviderScope(child: BorahApp()));
      await signInViaUi(tester, email: email, password: password);
      await openProfile(tester);

      expect(find.text(fullName), findsOneWidget);
      expect(find.text(bio), findsOneWidget);

      await logoutViaUi(tester);
      await signInViaUi(tester, email: email, password: password);
      await openProfile(tester);

      expect(
        find.text(fullName),
        findsOneWidget,
        reason: 'O nome deveria continuar salvo após logout/login.',
      );
      expect(
        find.text(bio),
        findsOneWidget,
        reason: 'A biografia deveria continuar salva após logout/login.',
      );

      final profile = await userHelper.fetchProfile(createdUserId!);
      expect(profile, isNotNull);
      expect(profile!['full_name'], fullName);
      expect(profile['bio'], bio);
    },
  );
}
