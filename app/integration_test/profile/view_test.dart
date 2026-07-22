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

/// QA-03, Rodada E, cenário 1 (Visualização do Perfil). Os campos são
/// preenchidos diretamente via PostgREST (precondição - "atualizar
/// perfil" já é validado em `update_test.dart`, mantendo os cenários
/// independentes, mesmo critério da Rodada C).
///
/// **Limitações conhecidas (achados da ETAPA 0, não corrigidas nesta
/// rodada):**
/// - `ProfilePage` não exibe e-mail (gerenciado pelo módulo de
///   Autenticação, DV-02 §3, fora da entidade `UserProfile`) nem
///   estatísticas/nível/XP/badges (fora do escopo do DV-02 §5 - decisão
///   já documentada no próprio código de `ProfilePage`, que lista
///   UX-02 §14 como wireframe mais rico do que o implementado) - por
///   isso este teste não valida esses campos.
/// - Nenhum bucket de Storage existe em `borah-qa` nem em Development
///   (achado da Rodada 0) - o avatar só pode ser validado como
///   placeholder (`Icons.person`), nunca upload real.
///
/// Executar com:
/// flutter test integration_test/profile/view_test.dart \
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
    'visualização do perfil carrega nome, bio, localização e placeholder '
    'de avatar, consistentes com o banco',
    (tester) async {
      final email =
          'qa-profile-view-${DateTime.now().millisecondsSinceEpoch}'
          '@borah.test';
      createdUserId = await userHelper.createTestUser(
        email: email,
        password: password,
      );
      final fullName =
          'QA Profile View ${DateTime.now().millisecondsSinceEpoch}';
      await userHelper.updateProfileFields(createdUserId!, {
        'full_name': fullName,
        'bio': 'Bio de teste (QA-03).',
        'city': 'São Paulo',
        'state': 'SP',
      });

      await initializeSupabase();
      await tester.pumpWidget(const ProviderScope(child: BorahApp()));
      await signInViaUi(tester, email: email, password: password);
      await openProfile(tester);

      expect(find.text(fullName), findsOneWidget);
      expect(find.text('Bio de teste (QA-03).'), findsOneWidget);
      expect(find.text('São Paulo, SP'), findsOneWidget);
      // Sem avatar_url definido - o placeholder deve aparecer.
      expect(find.byIcon(Icons.person), findsOneWidget);

      final profile = await userHelper.fetchProfile(createdUserId!);
      expect(profile, isNotNull);
      expect(profile!['full_name'], fullName);
      expect(profile['bio'], 'Bio de teste (QA-03).');
      expect(profile['city'], 'São Paulo');
      expect(profile['state'], 'SP');
    },
  );
}
