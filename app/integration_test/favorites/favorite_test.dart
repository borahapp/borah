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

/// QA-03, Rodada D, cenário 1 (Favoritar restaurante). Dirige o ícone
/// real de `RestaurantDetailPage` (`tooltip: 'Favoritar restaurante'`) -
/// é o próprio fluxo de favoritar que está sendo validado.
///
/// "Impedir favoritos duplicados" (DV-06 §3) é garantido pela constraint
/// `UNIQUE(user_id, restaurant_id)` do banco
/// (`20260719140000_create_favorites.sql`), não pela UI - o botão é um
/// toggle (dois toques seguidos favoritam e desfavoritam, nunca
/// duplicam). Por isso a garantia é validada tentando um insert
/// duplicado diretamente via [QaSocialHelper], esperando a violação de
/// unicidade.
///
/// O teste também exercita o segundo toque no mesmo botão (toggle de
/// volta para desfavoritado), confirmando que o ícone sempre reflete um
/// único estado consistente com o banco - nunca duplica nem diverge
/// entre os dois toques.
///
/// Executar com:
/// flutter test integration_test/favorites/favorite_test.dart \
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

  testWidgets('favoritar restaurante inclui nos favoritos, persiste no banco, '
      'atualiza a interface, impede duplicados e alterna para um único '
      'estado consistente', (tester) async {
    final email =
        'qa-favorite-${DateTime.now().millisecondsSinceEpoch}@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );
    final restaurantName =
        'QA Favorite Test ${DateTime.now().millisecondsSinceEpoch}';
    createdRestaurantId = await restaurantHelper.createRestaurant(
      createdBy: createdUserId!,
      name: restaurantName,
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: email, password: password);
    await openRestaurantByName(tester, restaurantName);

    // Ainda não favoritado - o ícone começa como `favorite_border`.
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byTooltip('Favoritar restaurante'));
    await pumpUntil(
      tester,
      () => find.byIcon(Icons.favorite).evaluate().isNotEmpty,
      timeoutMessage: 'O ícone não mudou para favoritado a tempo.',
    );

    final favorite = await socialHelper.fetchFavorite(
      createdUserId!,
      createdRestaurantId!,
    );
    expect(
      favorite,
      isNotNull,
      reason: 'O favorito deveria existir em favorites após o toque.',
    );

    await expectLater(
      socialHelper.addFavorite(createdUserId!, createdRestaurantId!),
      throwsA(isA<StateError>()),
    );

    // Segundo toque no mesmo botão: alterna de volta para desfavoritado
    // - confirma que o ícone reflete sempre um único estado consistente
    // (favoritado XOR não), nunca ambos nem nenhum.
    await tester.tap(find.byTooltip('Favoritar restaurante'));
    await pumpUntil(
      tester,
      () => find.byIcon(Icons.favorite_border).evaluate().isNotEmpty,
      timeoutMessage: 'O ícone não voltou para desfavoritado a tempo.',
    );
    expect(find.byIcon(Icons.favorite), findsNothing);

    final favoriteAfterToggleOff = await socialHelper.fetchFavorite(
      createdUserId!,
      createdRestaurantId!,
    );
    expect(
      favoriteAfterToggleOff,
      isNull,
      reason:
          'O segundo toque deveria remover o favorito, sem deixar '
          'nenhuma linha duplicada ou órfã em favorites.',
    );
  });
}
