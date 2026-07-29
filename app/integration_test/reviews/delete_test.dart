import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/qa_environment.dart';
import '../helpers/qa_restaurant_helper.dart';
import '../helpers/qa_test_config.dart';
import '../helpers/test_user_helper.dart';
import '../helpers/ui_flows.dart';

/// QA-03, Rodada C, cenário 5 (Excluir avaliação). A avaliação inicial é
/// criada diretamente via PostgREST (precondição rápida); a exclusão em
/// si é sempre feita pela UI real (`ReviewDetailPage` -> "Excluir").
///
/// A exclusão é lógica (`deleted_at`, DV-04 §16) - a linha continua
/// existindo em `reviews`, então a limpeza final ainda precisa de um
/// hard delete via [QaRestaurantHelper.deleteReview] antes de remover o
/// restaurante (`ON DELETE RESTRICT`).
///
/// **Achado de divergência (não corrigido, fora do escopo desta
/// rodada)**: ao voltar da exclusão para `ReviewsListPage` (pop), o item
/// excluído continua aparecendo na lista, obsoleto - a tela não recarrega
/// seus dados ao ser reexibida via navegação de retorno (mesma classe de
/// achado já documentada para `FavoritesPage`/`FeedPage` nas rodadas de
/// Widget Testing). Por isso este teste não afirma nada sobre o estado
/// visual da lista após a exclusão; "remoção" (lógica) e "atualização das
/// estatísticas" são validadas diretamente no backend.
///
/// Executar com:
/// flutter test integration_test/reviews/delete_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  late QaRestaurantHelper restaurantHelper;
  String? createdUserId;
  String? createdRestaurantId;
  String? createdReviewId;
  const password = 'SenhaForte123';

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
    userHelper = QaTestConfig.buildUserHelper();
    restaurantHelper = QaTestConfig.buildRestaurantHelper();
  });

  tearDown(() async {
    // A exclusão feita pelo teste é lógica - a linha ainda existe e
    // precisa de hard delete aqui antes do restaurante/usuário.
    if (createdReviewId != null) {
      await restaurantHelper.deleteReview(createdReviewId!);
      createdReviewId = null;
    }
    if (createdRestaurantId != null) {
      await restaurantHelper.deleteRestaurant(createdRestaurantId!);
      createdRestaurantId = null;
    }
    if (createdUserId != null) {
      await userHelper.deleteTestUser(createdUserId!);
      createdUserId = null;
    }
  });

  testWidgets('excluir avaliação remove logicamente e zera as estatísticas do '
      'restaurante', (tester) async {
    final email =
        'qa-review-delete-${DateTime.now().millisecondsSinceEpoch}'
        '@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );
    final restaurantName =
        'QA Review Delete Test ${DateTime.now().millisecondsSinceEpoch}';
    createdRestaurantId = await restaurantHelper.createRestaurant(
      createdBy: createdUserId!,
      name: restaurantName,
    );
    createdReviewId = await restaurantHelper.createReview(
      restaurantId: createdRestaurantId!,
      userId: createdUserId!,
      rating: 4,
      comment: 'Para excluir (QA-03).',
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: email, password: password);
    await openRestaurantByName(tester, restaurantName);

    await tester.tap(find.text('Ver avaliações'));
    await pumpUntil(
      tester,
      () => find.text('4.0').evaluate().isNotEmpty,
      timeoutMessage: 'A avaliação de precondição não apareceu na lista.',
    );

    await tester.tap(find.text('4.0'));
    await pumpUntil(
      tester,
      () => find.widgetWithText(TextButton, 'Excluir').evaluate().isNotEmpty,
      timeoutMessage: 'O Detalhe da Avaliação não abriu a tempo.',
    );

    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));

    // Após "Excluir", a tela volta para a ReviewsListPage (pop). Não há
    // como esperar por "Nenhuma avaliação ainda." aqui: **achado real**
    // (não é bug de teste) - `ReviewsListPage` não recarrega seus dados
    // ao ser reexibida via pop, então o item recém-excluído continua
    // visível de forma obsoleta (mesma classe de divergência já
    // documentada para FavoritesPage/FeedPage nas rodadas de Widget
    // Testing: sem gatilho de refresh no retorno de navegação). Como as
    // regras desta rodada proíbem alterar código de app/regras de
    // negócio, o teste não afirma nada sobre o estado visual da lista
    // após a exclusão - a validação de "remoção" e "atualização das
    // estatísticas" é feita diretamente no backend abaixo, que é onde a
    // exclusão lógica e o recálculo realmente acontecem.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    final review = await restaurantHelper.fetchReview(createdReviewId!);
    expect(review, isNotNull);
    expect(
      review!['deleted_at'],
      isNotNull,
      reason: 'A exclusão é lógica - a linha deve continuar existindo.',
    );

    final restaurantAfter = await restaurantHelper.fetchRestaurant(
      createdRestaurantId!,
    );
    expect(restaurantAfter!['average_rating'], isNull);
    expect((restaurantAfter['total_reviews'] as num).toInt(), 0);
  });
}
