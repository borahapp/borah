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

/// QA-03, Rodada D, cenário 5 (Atualização do Feed) - uma nova avaliação
/// de quem o usuário segue aparece após "puxar para atualizar"
/// (`RefreshIndicator`, DV-07 §10/§11).
///
/// Diferente de `ReviewsListPage` (Rodada C, achado de divergência
/// documentado em `reviews/delete_test.dart` - sem gatilho de refresh no
/// retorno de navegação), `FeedPage` **tem** um gatilho de UI real para
/// recarregar (`RefreshIndicator`), já validado por Widget Test
/// (`test/widget/social/feed_page_test.dart`). Este cenário aciona o
/// mesmo gesto (`tester.fling` no `ListView`) contra o backend real.
///
/// A avaliação inicial usa um restaurante diferente da nova avaliação -
/// a constraint `UNIQUE(user_id, restaurant_id)` de `reviews` impede
/// duas avaliações do mesmo usuário no mesmo restaurante (Rodada C).
///
/// Executar com:
/// flutter test integration_test/social/feed_update_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  late QaRestaurantHelper restaurantHelper;
  late QaSocialHelper socialHelper;
  String? createdViewerId;
  String? createdAuthorId;
  String? createdRestaurantInitialId;
  String? createdRestaurantNewId;
  String? createdReviewInitialId;
  String? createdReviewNewId;
  const password = 'SenhaForte123';

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
    userHelper = QaTestConfig.buildUserHelper();
    restaurantHelper = QaTestConfig.buildRestaurantHelper();
    socialHelper = QaTestConfig.buildSocialHelper();
  });

  tearDown(() async {
    if (createdReviewInitialId != null) {
      await restaurantHelper.deleteReview(createdReviewInitialId!);
      createdReviewInitialId = null;
    }
    if (createdReviewNewId != null) {
      await restaurantHelper.deleteReview(createdReviewNewId!);
      createdReviewNewId = null;
    }
    if (createdRestaurantInitialId != null) {
      await restaurantHelper.deleteRestaurant(createdRestaurantInitialId!);
      createdRestaurantInitialId = null;
    }
    if (createdRestaurantNewId != null) {
      await restaurantHelper.deleteRestaurant(createdRestaurantNewId!);
      createdRestaurantNewId = null;
    }
    if (createdAuthorId != null) {
      await userHelper.deleteTestUser(createdAuthorId!);
      createdAuthorId = null;
    }
    if (createdViewerId != null) {
      await userHelper.deleteTestUser(createdViewerId!);
      createdViewerId = null;
    }
  });

  testWidgets('puxar para atualizar traz uma nova avaliação de quem o usuário '
      'segue, mantendo a anterior visível', (tester) async {
    final suffix = DateTime.now().millisecondsSinceEpoch;
    final viewerEmail = 'qa-feed-upd-viewer-$suffix@borah.test';
    final authorEmail = 'qa-feed-upd-author-$suffix@borah.test';
    createdViewerId = await userHelper.createTestUser(
      email: viewerEmail,
      password: password,
    );
    createdAuthorId = await userHelper.createTestUser(
      email: authorEmail,
      password: password,
    );

    createdRestaurantInitialId = await restaurantHelper.createRestaurant(
      createdBy: createdAuthorId!,
      name: 'QA Feed Update Initial $suffix',
    );
    createdReviewInitialId = await restaurantHelper.createReview(
      restaurantId: createdRestaurantInitialId!,
      userId: createdAuthorId!,
      rating: 3,
      comment: 'Avaliação inicial (QA-03).',
    );

    await socialHelper.follow(createdViewerId!, createdAuthorId!);

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: viewerEmail, password: password);
    await openFeed(tester);

    await pumpUntil(
      tester,
      () => find.text('3.0').evaluate().isNotEmpty,
      timeoutMessage: 'O feed não carregou a avaliação inicial a tempo.',
    );

    // Nova atividade de quem o usuário segue, publicada enquanto a
    // tela do Feed já está aberta - simula outro usuário avaliando um
    // novo restaurante.
    createdRestaurantNewId = await restaurantHelper.createRestaurant(
      createdBy: createdAuthorId!,
      name: 'QA Feed Update New $suffix',
    );
    createdReviewNewId = await restaurantHelper.createReview(
      restaurantId: createdRestaurantNewId!,
      userId: createdAuthorId!,
      rating: 5,
      comment: 'Avaliação nova (QA-03).',
    );

    // Mesmo gesto já validado por Widget Test para o RefreshIndicator
    // do FeedPage (`test/widget/social/feed_page_test.dart`).
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await pumpUntil(
      tester,
      () => find.text('5.0').evaluate().isNotEmpty,
      timeoutMessage: 'A nova avaliação não apareceu no feed após atualizar.',
    );

    // Atualização da lista: a avaliação anterior continua visível
    // junto da nova (consistente com FeedController._run, que
    // concatena apenas em loadNextPage, mas aqui refresh() troca a
    // página 1 inteira - como a nova avaliação é mais recente, ambas
    // devem estar dentro do limite de 20 itens da mesma página).
    expect(find.text('3.0'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
  });
}
