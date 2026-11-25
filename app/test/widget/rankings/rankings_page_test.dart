import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/rankings/data/ranking_repository_impl.dart';
import 'package:app/features/rankings/domain/ranked_restaurant.dart';
import 'package:app/features/rankings/domain/ranking_repository.dart';
import 'package:app/features/rankings/domain/ranking_scope.dart';
import 'package:app/features/rankings/presentation/pages/rankings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRankingRepository extends Mock implements RankingRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

RankedRestaurant _ranked({
  String id = 'r-1',
  String name = 'Bar do Zé',
  double rating = 4.5,
  int? reviewsCount = 10,
}) {
  return RankedRestaurant(
    restaurantId: id,
    name: name,
    category: 'Bar',
    rating: rating,
    reviewsCount: reviewsCount,
  );
}

Widget _wrap(
  MockRankingRepository rankingRepository,
  MockGroupRepository groupRepository,
) {
  return ProviderScope(
    overrides: [
      rankingRepositoryProvider.overrideWithValue(rankingRepository),
      groupRepositoryProvider.overrideWithValue(groupRepository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: const MaterialApp(home: RankingsPage()),
  );
}

void main() {
  late MockRankingRepository rankingRepository;
  late MockGroupRepository groupRepository;

  setUp(() {
    rankingRepository = MockRankingRepository();
    groupRepository = MockGroupRepository();

    when(
      () => rankingRepository.list(
        scope: RankingScope.global,
        groupId: null,
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async =>
          PagedResult(items: [_ranked()], page: 1, limit: 20, hasNextPage: false),
    );
    when(
      () => groupRepository.listMine(),
    ).thenAnswer((_) async => []);
  });

  testWidgets('mostra os 3 segmentos: Global, Pessoal e Grupo', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(rankingRepository, groupRepository));
    await tester.pumpAndSettle();

    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Pessoal'), findsOneWidget);
    expect(find.text('Grupo'), findsOneWidget);
  });

  testWidgets('escopo Global mostra nota e contagem', (tester) async {
    await tester.pumpWidget(_wrap(rankingRepository, groupRepository));
    await tester.pumpAndSettle();

    expect(find.text('Bar do Zé'), findsOneWidget);
    expect(find.text('4.5 (10)'), findsOneWidget);
  });

  testWidgets('trocar para Pessoal busca pelo usuário atual e mostra "Sua '
      'nota"', (tester) async {
    when(
      () => rankingRepository.list(
        scope: RankingScope.personal,
        groupId: null,
        userId: 'user-1',
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_ranked(name: 'Trattoria', rating: 5, reviewsCount: null)],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(_wrap(rankingRepository, groupRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pessoal'));
    await tester.pumpAndSettle();

    expect(find.text('Trattoria'), findsOneWidget);
    expect(find.text('Sua nota: 5.0'), findsOneWidget);
  });

  testWidgets('trocar para Grupo sem nenhum grupo mostra o estado vazio '
      'certo', (tester) async {
    await tester.pumpWidget(_wrap(rankingRepository, groupRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grupo'));
    await tester.pumpAndSettle();

    expect(
      find.text('Você precisa participar de um grupo para ver este ranking.'),
      findsOneWidget,
    );
  });

  testWidgets('trocar para Grupo com grupos disponíveis pede para escolher '
      'um, e depois de escolhido busca o ranking do grupo', (tester) async {
    when(() => groupRepository.listMine()).thenAnswer(
      (_) async => [
        const Group(
          id: 'group-1',
          name: 'Amigos do rolê',
          description: null,
          photoUrl: null,
          inviteCode: 'ABC123',
        ),
      ],
    );
    when(
      () => rankingRepository.list(
        scope: RankingScope.group,
        groupId: 'group-1',
        userId: null,
        city: null,
        state: null,
        country: null,
        category: null,
        page: 1,
        limit: 20,
      ),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_ranked(name: 'Churrascaria', rating: 4.8, reviewsCount: 3)],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await tester.pumpWidget(_wrap(rankingRepository, groupRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grupo'));
    await tester.pumpAndSettle();

    expect(
      find.text('Escolha um grupo para ver seu ranking de restaurantes.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Selecionar grupo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amigos do rolê'));
    await tester.pumpAndSettle();

    expect(find.text('Churrascaria'), findsOneWidget);
    expect(find.text('4.8 (3 avaliações do grupo)'), findsOneWidget);
  });
}
