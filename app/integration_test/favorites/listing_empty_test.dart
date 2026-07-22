import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/qa_environment.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada D, cenário 3 (Listagem de favoritos) - estado vazio.
/// Arquivo separado de `listing_test.dart` (isolamento de processo/
/// sessão, mesmo motivo documentado em `restaurants/listing_test.dart`,
/// Rodada C).
///
/// Executar com:
/// flutter test integration_test/favorites/listing_empty_test.dart \
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

  testWidgets('estado vazio mostra mensagem para usuário sem favoritos', (
    tester,
  ) async {
    final email =
        'qa-fav-empty-${DateTime.now().millisecondsSinceEpoch}@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: email, password: password);
    await openFavorites(tester);

    await pumpUntil(
      tester,
      () => find.text('Você ainda não tem favoritos.').evaluate().isNotEmpty,
      timeoutMessage: 'O estado vazio de favoritos não apareceu a tempo.',
    );
  });
}
