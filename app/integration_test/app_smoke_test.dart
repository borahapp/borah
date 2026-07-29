import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/qa_environment.dart';

/// Smoke test do QA-03 (Rodada A - scaffolding). Escopo estritamente
/// mínimo: inicializa a aplicação de verdade contra o ambiente QA real,
/// confirma que a conexão com o Supabase funciona (a própria
/// `Supabase.initialize` falharia se a URL/chave fossem inválidas) e
/// que a Splash redireciona corretamente para o Login. Nenhum
/// cadastro, login ou dado é criado.
///
/// Executar com:
/// flutter test integration_test/app_smoke_test.dart --dart-define-from-file=.env.qa
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
  });

  testWidgets('app inicializa, conecta ao ambiente QA e abre a tela de Login', (
    tester,
  ) async {
    await initializeSupabase();

    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await tester.pump();

    // A Splash mostra um `CircularProgressIndicator` indeterminado
    // enquanto restaura a sessão - `pumpAndSettle` nunca retornaria
    // enquanto ele estiver visível (animação infinita). Por isso o
    // aguardo é feito com pumps limitados até a navegação real para
    // o Login acontecer (chamada de rede real ao Supabase QA).
    var attempts = 0;
    while (find.text('BORAH').evaluate().isEmpty && attempts < 50) {
      await tester.pump(const Duration(milliseconds: 200));
      attempts++;
    }

    expect(
      find.text('BORAH'),
      findsOneWidget,
      reason:
          'A Splash deveria ter redirecionado para o Login após '
          'restaurar a sessão contra o ambiente QA real.',
    );
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
