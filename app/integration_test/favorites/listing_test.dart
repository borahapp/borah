import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:app/features/favorites/domain/favorite_sort_by.dart';
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

/// QA-03, Rodada D, cenário 3 (Listagem de favoritos) - carregamento,
/// ordenação e consistência dos dados. O estado vazio está em
/// `listing_empty_test.dart` (arquivo separado - cada `integration_test`
/// roda em seu próprio processo, mesmo motivo já documentado em
/// `restaurants/listing_test.dart`, Rodada C).
///
/// Ambos os favoritos são criados diretamente via PostgREST (precondição
/// rápida - "favoritar" já é validado em `favorite_test.dart`).
///
/// Executar com:
/// flutter test integration_test/favorites/listing_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  late QaRestaurantHelper restaurantHelper;
  late QaSocialHelper socialHelper;
  String? createdUserId;
  String? createdRestaurantAId;
  String? createdRestaurantZId;
  const password = 'SenhaForte123';

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
    userHelper = QaTestConfig.buildUserHelper();
    restaurantHelper = QaTestConfig.buildRestaurantHelper();
    socialHelper = QaTestConfig.buildSocialHelper();
  });

  tearDown(() async {
    if (createdRestaurantAId != null) {
      await restaurantHelper.deleteRestaurant(createdRestaurantAId!);
      createdRestaurantAId = null;
    }
    if (createdRestaurantZId != null) {
      await restaurantHelper.deleteRestaurant(createdRestaurantZId!);
      createdRestaurantZId = null;
    }
    if (createdUserId != null) {
      await userHelper.deleteTestUser(createdUserId!);
      createdUserId = null;
    }
  });

  testWidgets(
    'listagem carrega os favoritos, ordena por nome e mantém os dados '
    'consistentes com o restaurante',
    (tester) async {
      final email =
          'qa-fav-listing-${DateTime.now().millisecondsSinceEpoch}'
          '@borah.test';
      createdUserId = await userHelper.createTestUser(
        email: email,
        password: password,
      );
      final suffix = DateTime.now().millisecondsSinceEpoch;
      final nameA = 'AAA QA Favorite Listing $suffix';
      final nameZ = 'ZZZ QA Favorite Listing $suffix';
      createdRestaurantAId = await restaurantHelper.createRestaurant(
        createdBy: createdUserId!,
        name: nameA,
        category: 'Bar',
      );
      createdRestaurantZId = await restaurantHelper.createRestaurant(
        createdBy: createdUserId!,
        name: nameZ,
        category: 'Bar',
      );
      // Ordem de criação intencional: Z favoritado depois de A, para que
      // a ordenação padrão (mais recentes) e a ordenação por nome
      // produzam resultados diferentes e comparáveis.
      await socialHelper.addFavorite(createdUserId!, createdRestaurantAId!);
      await socialHelper.addFavorite(createdUserId!, createdRestaurantZId!);

      await initializeSupabase();
      await tester.pumpWidget(const ProviderScope(child: BorahApp()));
      await signInViaUi(tester, email: email, password: password);
      await openFavorites(tester);

      await pumpUntil(
        tester,
        () =>
            find.widgetWithText(ListTile, nameA).evaluate().isNotEmpty &&
            find.widgetWithText(ListTile, nameZ).evaluate().isNotEmpty,
        timeoutMessage: 'A listagem de favoritos não carregou a tempo.',
      );

      // Consistência dos dados: subtítulo mostra a categoria do
      // restaurante criado.
      final tileA = tester.widget<ListTile>(
        find.widgetWithText(ListTile, nameA),
      );
      expect((tileA.subtitle! as Text).data, contains('Bar'));

      await tester.tap(find.byType(DropdownButton<FavoriteSortBy>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nome').last);
      await pumpUntil(
        tester,
        () =>
            find.widgetWithText(ListTile, nameA).evaluate().isNotEmpty &&
            find.widgetWithText(ListTile, nameZ).evaluate().isNotEmpty,
        timeoutMessage: 'A lista não recarregou após ordenar por nome.',
      );

      // Ordenação por nome (ascendente) - "AAA..." deve aparecer antes de
      // "ZZZ...".
      final yA = tester.getCenter(find.widgetWithText(ListTile, nameA)).dy;
      final yZ = tester.getCenter(find.widgetWithText(ListTile, nameZ)).dy;
      expect(
        yA,
        lessThan(yZ),
        reason: 'Ordenado por nome, "AAA..." deveria vir antes de "ZZZ...".',
      );
    },
  );
}
