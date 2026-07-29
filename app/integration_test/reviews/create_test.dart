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

/// QA-03, Rodada C, cenário 3 (Criar avaliação). Dirige o formulário
/// real de `CreateReviewPage` - é o próprio fluxo de criação que está
/// sendo validado, diferente do restaurante de precondição (criado
/// diretamente via PostgREST, já que cadastro de restaurante não é um
/// dos cenários desta rodada).
///
/// Executar com:
/// flutter test integration_test/reviews/create_test.dart \
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
    // Ordem importa: reviews.restaurant_id/user_id usam ON DELETE
    // RESTRICT - a avaliação precisa ser removida antes do restaurante
    // e do usuário.
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

  testWidgets(
    'criar avaliação persiste os dados, atualiza a média do restaurante '
    'e reflete na interface',
    (tester) async {
      final email =
          'qa-review-create-${DateTime.now().millisecondsSinceEpoch}'
          '@borah.test';
      createdUserId = await userHelper.createTestUser(
        email: email,
        password: password,
      );
      final restaurantName =
          'QA Review Create Test ${DateTime.now().millisecondsSinceEpoch}';
      createdRestaurantId = await restaurantHelper.createRestaurant(
        createdBy: createdUserId!,
        name: restaurantName,
      );

      await initializeSupabase();
      await tester.pumpWidget(const ProviderScope(child: BorahApp()));
      await signInViaUi(tester, email: email, password: password);
      await openRestaurantByName(tester, restaurantName);

      await tester.tap(find.text('Ver avaliações'));
      await pumpUntil(
        tester,
        () => find.text('Nenhuma avaliação ainda.').evaluate().isNotEmpty,
        timeoutMessage: 'A lista de avaliações não abriu a tempo.',
      );

      // `.last`: a RestaurantsSearchPage anterior continua montada por
      // baixo (push não a descarta) e também tem um IconButton
      // `Icons.add` ("Adicionar restaurante") - o da tela atual
      // (ReviewsListPage) é o mais recentemente inserido na árvore.
      await tester.tap(find.byIcon(Icons.add).last);
      await pumpUntil(
        tester,
        () => find
            .widgetWithText(TextFormField, 'Nota (1 a 5)')
            .evaluate()
            .isNotEmpty,
        timeoutMessage: 'A tela de Criar Avaliação não abriu a tempo.',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nota (1 a 5)'),
        '5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Comentário (opcional)'),
        'Ótima experiência de teste (QA-03).',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Publicar avaliação'));

      await pumpUntil(
        tester,
        () => find.text('5.0').evaluate().isNotEmpty,
        maxAttempts: 100,
        timeoutMessage: 'Não navegou para o Detalhe da Avaliação a tempo.',
      );

      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('Ótima experiência de teste (QA-03).'), findsOneWidget);

      // Descobre o id da avaliação recém-criada (a UI não expõe o id
      // diretamente) para validar persistência e limpar ao final.
      final review = await restaurantHelper.fetchReviewByRestaurantAndUser(
        restaurantId: createdRestaurantId!,
        userId: createdUserId!,
      );
      expect(
        review,
        isNotNull,
        reason: 'A avaliação deveria existir em reviews após a criação.',
      );
      createdReviewId = review!['id'] as String;
      expect((review['rating'] as num).toDouble(), 5.0);
      expect(review['comment'], 'Ótima experiência de teste (QA-03).');

      final restaurantAfter = await restaurantHelper.fetchRestaurant(
        createdRestaurantId!,
      );
      expect(restaurantAfter, isNotNull);
      expect((restaurantAfter!['total_reviews'] as num).toInt(), 1);
      expect((restaurantAfter['average_rating'] as num).toDouble(), 5.0);
    },
  );
}
