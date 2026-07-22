import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/qa_environment.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada E, cenário 5 (Estados) - perfil vazio. Arquivo separado
/// de `state_partial_test.dart` (isolamento de processo/sessão, mesmo
/// motivo documentado em `restaurants/listing_test.dart`, Rodada C).
///
/// Um usuário recém-criado já nasce com `full_name = ''` e
/// `bio`/`city`/`state` nulos (trigger `handle_new_user`,
/// `20260718180242_create_profiles.sql`) - precondição natural, sem
/// necessidade de setup extra.
///
/// **Não cobertos neste arquivo (achados da ETAPA 0):** "carregamento"
/// é transiente demais para uma asserção confiável contra um backend
/// real (já coberto com timing controlado por Widget Test); "tratamento
/// de erro" não tem forma confiável de ser forçado contra um backend
/// saudável sem manipular rede - mesma conclusão já registrada em
/// `restaurants/listing_test.dart` (Rodada C).
///
/// Executar com:
/// flutter test integration_test/profile/state_empty_test.dart \
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
    'perfil recém-criado mostra estado vazio: sem nome, sem biografia, '
    'sem localização, placeholder de avatar',
    (tester) async {
      final email =
          'qa-profile-empty-${DateTime.now().millisecondsSinceEpoch}'
          '@borah.test';
      createdUserId = await userHelper.createTestUser(
        email: email,
        password: password,
      );

      await initializeSupabase();
      await tester.pumpWidget(const ProviderScope(child: BorahApp()));
      await signInViaUi(tester, email: email, password: password);
      await openProfile(tester);

      expect(find.text('Sem nome'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(
        find.text('Editar perfil'),
        findsOneWidget,
        reason: 'A tela deveria carregar normalmente mesmo sem dados.',
      );

      final profile = await userHelper.fetchProfile(createdUserId!);
      expect(profile, isNotNull);
      expect(profile!['full_name'], '');
      expect(profile['bio'], isNull);
      expect(profile['city'], isNull);
      expect(profile['state'], isNull);
    },
  );
}
