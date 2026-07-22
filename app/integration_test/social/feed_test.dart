import 'package:app/app.dart';
import 'package:app/core/network/supabase_client_provider.dart';
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

/// QA-03, Rodada D, cenário 4 (Feed Social) - carregamento, exibição e
/// ordenação. A relação de seguidor e as avaliações são criadas
/// diretamente via PostgREST (precondição - "seguir usuário" não é um
/// cenário desta rodada, e "criar avaliação" já foi validado na
/// Rodada C).
///
/// Duas avaliações do mesmo autor, cada uma em um restaurante diferente
/// (a constraint `UNIQUE(user_id, restaurant_id)` de `reviews` impede
/// duas avaliações do mesmo usuário no mesmo restaurante - ver
/// `qa_restaurant_helper.dart`, Rodada C).
///
/// **Limitação real conhecida (achado na ETAPA 0 de análise, não
/// corrigida nesta rodada):** `ReviewSummaryTile` - usado por `FeedPage`
/// - exibe somente nota e comentário; nenhuma informação de usuário,
/// nome do restaurante ou data aparece na interface do Feed, apesar de
/// DV-07 §4/§5/§11 exigirem essas informações (mesma classe de
/// divergência já registrada para `ReviewDetailPage`, EX-10 §3 Item 2 -
/// ausência de Data/Autor). Por isso "informações do usuário",
/// "restaurante relacionado" e "data" são validados diretamente no
/// backend abaixo, não pela interface.
///
/// Executar com:
/// flutter test integration_test/social/feed_test.dart \
///   --dart-define-from-file=.env.qa \
///   --dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late QaTestUserHelper userHelper;
  late QaRestaurantHelper restaurantHelper;
  late QaSocialHelper socialHelper;
  String? createdViewerId;
  String? createdAuthorId;
  String? createdRestaurantOldId;
  String? createdRestaurantNewId;
  String? createdReviewOldId;
  String? createdReviewNewId;
  const password = 'SenhaForte123';

  setUpAll(() {
    QaEnvironment.assertRunningAgainstQaProject();
    userHelper = QaTestConfig.buildUserHelper();
    restaurantHelper = QaTestConfig.buildRestaurantHelper();
    socialHelper = QaTestConfig.buildSocialHelper();
  });

  tearDown(() async {
    // Ordem importa: reviews.restaurant_id/user_id usam ON DELETE
    // RESTRICT - as avaliações precisam ser removidas antes dos
    // restaurantes e dos usuários (mesma regra da Rodada C).
    if (createdReviewOldId != null) {
      await restaurantHelper.deleteReview(createdReviewOldId!);
      createdReviewOldId = null;
    }
    if (createdReviewNewId != null) {
      await restaurantHelper.deleteReview(createdReviewNewId!);
      createdReviewNewId = null;
    }
    if (createdRestaurantOldId != null) {
      await restaurantHelper.deleteRestaurant(createdRestaurantOldId!);
      createdRestaurantOldId = null;
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

  testWidgets(
    'feed carrega as avaliações de quem o usuário segue, ordenadas da '
    'mais recente para a mais antiga',
    (tester) async {
      final suffix = DateTime.now().millisecondsSinceEpoch;
      final viewerEmail = 'qa-feed-viewer-$suffix@borah.test';
      final authorEmail = 'qa-feed-author-$suffix@borah.test';
      createdViewerId = await userHelper.createTestUser(
        email: viewerEmail,
        password: password,
      );
      createdAuthorId = await userHelper.createTestUser(
        email: authorEmail,
        password: password,
      );

      createdRestaurantOldId = await restaurantHelper.createRestaurant(
        createdBy: createdAuthorId!,
        name: 'QA Feed Restaurant Old $suffix',
      );
      createdRestaurantNewId = await restaurantHelper.createRestaurant(
        createdBy: createdAuthorId!,
        name: 'QA Feed Restaurant New $suffix',
      );

      // Ordem de criação intencional: a avaliação "nova" é criada depois
      // da "antiga", para validar a ordenação por `created_at desc`.
      createdReviewOldId = await restaurantHelper.createReview(
        restaurantId: createdRestaurantOldId!,
        userId: createdAuthorId!,
        rating: 3,
        comment: 'Avaliação antiga (QA-03).',
      );
      createdReviewNewId = await restaurantHelper.createReview(
        restaurantId: createdRestaurantNewId!,
        userId: createdAuthorId!,
        rating: 5,
        comment: 'Avaliação nova (QA-03).',
      );

      await socialHelper.follow(createdViewerId!, createdAuthorId!);

      await initializeSupabase();
      await tester.pumpWidget(const ProviderScope(child: BorahApp()));
      await signInViaUi(tester, email: viewerEmail, password: password);
      await openFeed(tester);

      await pumpUntil(
        tester,
        () =>
            find.text('3.0').evaluate().isNotEmpty &&
            find.text('5.0').evaluate().isNotEmpty,
        timeoutMessage: 'O feed não carregou as duas avaliações a tempo.',
      );

      expect(find.text('Avaliação antiga (QA-03).'), findsOneWidget);
      expect(find.text('Avaliação nova (QA-03).'), findsOneWidget);

      // Ordenação: a avaliação mais nova ("5.0") deve aparecer acima da
      // mais antiga ("3.0").
      final yNew = tester.getCenter(find.text('5.0')).dy;
      final yOld = tester.getCenter(find.text('3.0')).dy;
      expect(
        yNew,
        lessThan(yOld),
        reason: 'A avaliação mais recente deveria aparecer primeiro.',
      );

      // Consistência dos dados (usuário/restaurante/data) - validada no
      // backend, já que a interface do Feed não os exibe (ver limitação
      // documentada no cabeçalho deste arquivo).
      final reviewOld = await restaurantHelper.fetchReview(createdReviewOldId!);
      final reviewNew = await restaurantHelper.fetchReview(createdReviewNewId!);
      expect(reviewOld!['user_id'], createdAuthorId);
      expect(reviewOld['restaurant_id'], createdRestaurantOldId);
      expect(reviewNew!['user_id'], createdAuthorId);
      expect(reviewNew['restaurant_id'], createdRestaurantNewId);
      expect(
        DateTime.parse(
          reviewNew['created_at'] as String,
        ).isAfter(DateTime.parse(reviewOld['created_at'] as String)),
        isTrue,
      );
    },
  );
}
