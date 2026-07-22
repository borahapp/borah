import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/qa_environment.dart';
import '../helpers/qa_restaurant_helper.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada C, cenário 2 (Detalhes do restaurante).
///
/// Executar com:
/// flutter test integration_test/restaurants/detail_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  late QaRestaurantHelper restaurantHelper;
  String? createdUserId;
  String? createdRestaurantId;
  const password = 'SenhaForte123';

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
    userHelper = QaTestConfig.buildUserHelper();
    restaurantHelper = QaTestConfig.buildRestaurantHelper();
  });

  tearDown(() async {
    if (createdRestaurantId != null) {
      await restaurantHelper.deleteRestaurant(createdRestaurantId!);
      createdRestaurantId = null;
    }
    if (createdUserId != null) {
      await userHelper.deleteTestUser(createdUserId!);
      createdUserId = null;
    }
  });

  testWidgets('detalhes mostram as informações principais e permitem ver as '
      'avaliações (vazias para um restaurante novo)', (tester) async {
    final email =
        'qa-detail-${DateTime.now().millisecondsSinceEpoch}@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );
    final restaurantName =
        'QA Detail Test ${DateTime.now().millisecondsSinceEpoch}';
    createdRestaurantId = await restaurantHelper.createRestaurant(
      createdBy: createdUserId!,
      name: restaurantName,
      category: 'Bar',
      description: 'Restaurante criado para o Integration Test de Detalhes.',
      address: 'Rua de Teste, 123',
      city: 'São Paulo',
      stateProvince: 'SP',
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: email, password: password);
    await openRestaurantByName(tester, restaurantName);

    // `findsWidgets` (não `findsOneWidget`): a RestaurantsSearchPage
    // anterior continua montada por baixo (push não a descarta) e ainda
    // mostra o mesmo nome no campo de busca e no item da lista.
    expect(find.text(restaurantName), findsWidgets);
    expect(find.text('Bar'), findsOneWidget);
    expect(find.text('Rua de Teste, 123, São Paulo, SP'), findsOneWidget);
    expect(
      find.text('Restaurante criado para o Integration Test de Detalhes.'),
      findsOneWidget,
    );
    // Sem avaliações ainda - a linha de nota média não deve aparecer
    // (RestaurantDetailPage só a exibe quando averageRating != null).
    expect(find.textContaining('avaliações)'), findsNothing);

    await tester.tap(find.text('Ver avaliações'));
    await pumpUntil(
      tester,
      () => find.text('Nenhuma avaliação ainda.').evaluate().isNotEmpty,
      timeoutMessage: 'A lista de avaliações não abriu a tempo.',
    );

    expect(find.text('Nenhuma avaliação ainda.'), findsOneWidget);
  });
}
