import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/ranking_entry.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/gamification/presentation/pages/ranking_users_page.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/domain/reviewer_ranking_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

RankingEntry _pointsEntry({String userId = 'user-1', String name = 'Ana'}) {
  return RankingEntry(
    progress: UserProgress(
      userId: userId,
      xp: 100,
      points: 100,
      level: 2,
      updatedAt: DateTime(2026, 1, 1),
    ),
    fullName: name,
  );
}

Widget _wrap(
  MockGamificationRepository gamificationRepository,
  MockReviewRepository reviewRepository,
) {
  return ProviderScope(
    overrides: [
      gamificationRepositoryProvider.overrideWithValue(gamificationRepository),
      reviewRepositoryProvider.overrideWithValue(reviewRepository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: const MaterialApp(home: RankingUsersPage()),
  );
}

void main() {
  late MockGamificationRepository gamificationRepository;
  late MockReviewRepository reviewRepository;

  setUp(() {
    gamificationRepository = MockGamificationRepository();
    reviewRepository = MockReviewRepository();

    when(
      () => gamificationRepository.listGlobalRanking(page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_pointsEntry()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
  });

  testWidgets('mostra as 3 abas: Global, Amigos e Avaliadores (rodada '
      '"perfil individual como centro", pós-FASE 09, Item E)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(gamificationRepository, reviewRepository));
    await tester.pumpAndSettle();

    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Amigos'), findsOneWidget);
    expect(find.text('Avaliadores'), findsOneWidget);
  });

  group('aba Avaliadores', () {
    testWidgets('mostra os avaliadores ordenados com a contagem de '
        'avaliações', (tester) async {
      when(
        () => reviewRepository.listTopReviewers(page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [
            ReviewerRankingEntry(
              userId: 'user-1',
              fullName: 'Carla',
              reviewsCount: 12,
            ),
            ReviewerRankingEntry(
              userId: 'user-2',
              fullName: 'Diego',
              reviewsCount: 1,
            ),
          ],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await tester.pumpWidget(_wrap(gamificationRepository, reviewRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avaliadores'));
      await tester.pumpAndSettle();

      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('12 avaliações'), findsOneWidget);
      expect(find.text('Diego'), findsOneWidget);
      expect(find.text('1 avaliação'), findsOneWidget);
    });

    testWidgets('sem avaliadores, mostra o estado vazio', (tester) async {
      when(
        () => reviewRepository.listTopReviewers(page: 1, limit: 20),
      ).thenAnswer(
        (_) async =>
            const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
      );

      await tester.pumpWidget(_wrap(gamificationRepository, reviewRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avaliadores'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum resultado ainda.'), findsOneWidget);
    });

    testWidgets('trocar de volta para Global continua funcionando', (
      tester,
    ) async {
      when(
        () => reviewRepository.listTopReviewers(page: 1, limit: 20),
      ).thenAnswer(
        (_) async =>
            const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
      );

      await tester.pumpWidget(_wrap(gamificationRepository, reviewRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avaliadores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Global'));
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('100 pts'), findsOneWidget);
    });
  });
}
