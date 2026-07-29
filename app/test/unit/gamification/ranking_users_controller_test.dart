import 'package:app/core/models/paged_result.dart';
import 'package:app/features/gamification/application/ranking_users_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/ranking_entry.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/gamification/presentation/states/ranking_users_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

RankingEntry _entry({String userId = 'user-2'}) {
  return RankingEntry(
    progress: UserProgress(
      userId: userId,
      xp: 100,
      points: 100,
      level: 1,
      updatedAt: DateTime(2026, 1, 1),
    ),
    fullName: 'Maria',
  );
}

void main() {
  late MockGamificationRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockGamificationRepository();
    container = ProviderContainer(
      overrides: [gamificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é RankingUsersInitial', () {
    expect(
      container.read(rankingUsersControllerProvider),
      isA<RankingUsersInitial>(),
    );
  });

  test('load(global) com resultados -> RankingUsersLoaded', () async {
    when(() => repository.listGlobalRanking(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(rankingUsersControllerProvider.notifier)
        .load('user-1', RankingUsersType.global);

    expect(
      container.read(rankingUsersControllerProvider),
      isA<RankingUsersLoaded>(),
    );
    verify(() => repository.listGlobalRanking(page: 1, limit: 20)).called(1);
  });

  test('load(friends) chama listFriendsRanking', () async {
    when(
      () => repository.listFriendsRanking('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_entry()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(rankingUsersControllerProvider.notifier)
        .load('user-1', RankingUsersType.friends);

    verify(
      () => repository.listFriendsRanking('user-1', page: 1, limit: 20),
    ).called(1);
  });

  test('sem resultados -> RankingUsersEmpty', () async {
    when(() => repository.listGlobalRanking(page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(rankingUsersControllerProvider.notifier)
        .load('user-1', RankingUsersType.global);

    expect(
      container.read(rankingUsersControllerProvider),
      isA<RankingUsersEmpty>(),
    );
  });

  test('com falha -> RankingUsersError', () async {
    when(
      () => repository.listGlobalRanking(page: 1, limit: 20),
    ).thenThrow(const GamificationRepositoryException('Falha.'));

    await container
        .read(rankingUsersControllerProvider.notifier)
        .load('user-1', RankingUsersType.global);

    expect(
      container.read(rankingUsersControllerProvider),
      isA<RankingUsersError>(),
    );
  });
}
