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

/// QA-03, Rodada C, cenário 4 (Editar avaliação). A avaliação inicial é
/// criada diretamente via PostgREST (precondição rápida - "criar
/// avaliação" já é validado em `create_test.dart`); a edição em si é
/// sempre feita pela UI real (`ReviewDetailPage` -> "Editar" ->
/// `EditReviewPage`, que reaproveita o estado já carregado pela tela de
/// Detalhes em vez de recarregar sozinha - DV-04).
///
/// Executar com:
/// flutter test integration_test/reviews/edit_test.dart \
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

  testWidgets('editar avaliação altera nota e comentário, persiste e recalcula '
      'a média do restaurante', (tester) async {
    final email =
        'qa-review-edit-${DateTime.now().millisecondsSinceEpoch}'
        '@borah.test';
    createdUserId = await userHelper.createTestUser(
      email: email,
      password: password,
    );
    final restaurantName =
        'QA Review Edit Test ${DateTime.now().millisecondsSinceEpoch}';
    createdRestaurantId = await restaurantHelper.createRestaurant(
      createdBy: createdUserId!,
      name: restaurantName,
    );
    createdReviewId = await restaurantHelper.createReview(
      restaurantId: createdRestaurantId!,
      userId: createdUserId!,
      rating: 3,
      comment: 'Comentário original.',
    );

    await initializeSupabase();
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await signInViaUi(tester, email: email, password: password);
    await openRestaurantByName(tester, restaurantName);

    await tester.tap(find.text('Ver avaliações'));
    await pumpUntil(
      tester,
      () => find.text('3.0').evaluate().isNotEmpty,
      timeoutMessage: 'A avaliação de precondição não apareceu na lista.',
    );

    await tester.tap(find.text('3.0'));
    await pumpUntil(
      tester,
      () => find.widgetWithText(OutlinedButton, 'Editar').evaluate().isNotEmpty,
      timeoutMessage: 'O Detalhe da Avaliação não abriu a tempo.',
    );

    // `findsWidgets` (não `findsOneWidget`): a ReviewsListPage anterior
    // continua montada por baixo (push não a descarta) e ainda mostra o
    // mesmo comentário no subtítulo do item da lista.
    expect(find.text('Comentário original.'), findsWidgets);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Editar'));
    await pumpUntil(
      tester,
      () => find
          .widgetWithText(TextFormField, 'Nota (1 a 5)')
          .evaluate()
          .isNotEmpty,
      timeoutMessage: 'A tela de Editar Avaliação não abriu a tempo.',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nota (1 a 5)'),
      '5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Comentário (opcional)'),
      'Comentário editado (QA-03).',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));

    await pumpUntil(
      tester,
      () => find.text('5.0').evaluate().isNotEmpty,
      maxAttempts: 100,
      timeoutMessage:
          'Não voltou ao Detalhe da Avaliação com os dados atualizados.',
    );

    expect(find.text('5.0'), findsOneWidget);
    // A ReviewsListPage anterior mostra o comentário/nota antigos de
    // forma obsoleta (ela não é recarregada ao voltar de outra tela) -
    // "Comentário editado" só pode estar na tela atual (ReviewDetailPage
    // recém-atualizada), então `findsOneWidget` aqui é confiável.
    expect(find.text('Comentário editado (QA-03).'), findsOneWidget);

    final review = await restaurantHelper.fetchReview(createdReviewId!);
    expect(review, isNotNull);
    expect((review!['rating'] as num).toDouble(), 5.0);
    expect(review['comment'], 'Comentário editado (QA-03).');

    final restaurantAfter = await restaurantHelper.fetchRestaurant(
      createdRestaurantId!,
    );
    expect(
      (restaurantAfter!['average_rating'] as num).toDouble(),
      5.0,
      reason:
          'A média do restaurante deveria refletir a nota já editada, '
          'não a original.',
    );
  });
}
