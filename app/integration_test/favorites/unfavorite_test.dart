import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/qa_environment.dart';
import '../helpers/qa_restaurant_helper.dart';
import '../helpers/qa_social_helper.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada D, cenário 2 (Remover favorito). O favorito inicial é
/// criado diretamente via PostgREST (precondição rápida - "favoritar" já
/// é validado em `favorite_test.dart`); a remoção em si é sempre feita
/// pela UI real.
///
/// `FavoritesPage` não tem ação de remoção direta na própria lista
/// (achado já documentado na rodada de Widget Testing do Tier 2,
/// EX-10 §3 Item 3) - a única forma real de desfavoritar é o mesmo
/// ícone de `RestaurantDetailPage` usado para favoritar.
///
/// Executar com:
/// flutter test integration_test/favorites/unfavorite_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  late QaRestaurantHelper restaurantHelper;
  late QaSocialHelper socialHelper;
  String? createdUserId;
  String? createdRestaurantId;
  const password = 'SenhaForte123';

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
    userHelper = QaTestConfig.buildUserHelper();
    restaurantHelper = QaTestConfig.buildRestaurantHelper();
    socialHelper = QaTestConfig.buildSocialHelper();
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

  testWidgets(
    'remover favorito desfavorita, persiste a remoção e atualiza a interface',
    (tester) async {
      final email =
          'qa-unfavorite-${DateTime.now().millisecondsSinceEpoch}@borah.test';
      createdUserId = await userHelper.createTestUser(
        email: email,
        password: password,
      );
      final restaurantName =
          'QA Unfavorite Test ${DateTime.now().millisecondsSinceEpoch}';
      createdRestaurantId = await restaurantHelper.createRestaurant(
        createdBy: createdUserId!,
        name: restaurantName,
      );
      await socialHelper.addFavorite(createdUserId!, createdRestaurantId!);

      await initializeSupabase();
      await tester.pumpWidget(const ProviderScope(child: BorahApp()));
      await signInViaUi(tester, email: email, password: password);
      await openRestaurantByName(tester, restaurantName);

      // Já favoritado pela precondição - o ícone deve refletir isso ao
      // carregar a tela.
      await pumpUntil(
        tester,
        () => find.byIcon(Icons.favorite).evaluate().isNotEmpty,
        timeoutMessage: 'O ícone não carregou como favoritado a tempo.',
      );

      await tester.tap(find.byTooltip('Favoritar restaurante'));
      await pumpUntil(
        tester,
        () => find.byIcon(Icons.favorite_border).evaluate().isNotEmpty,
        timeoutMessage: 'O ícone não mudou para desfavoritado a tempo.',
      );

      final favorite = await socialHelper.fetchFavorite(
        createdUserId!,
        createdRestaurantId!,
      );
      expect(
        favorite,
        isNull,
        reason: 'O favorito deveria ter sido removido de favorites.',
      );
    },
  );
}
