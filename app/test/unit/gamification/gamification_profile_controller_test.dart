import 'package:app/features/gamification/application/gamification_profile_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_badge.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/groups_activity_summary.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/gamification/presentation/states/gamification_profile_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

UserProgress _progress({int xp = 40, int level = 1}) {
  return UserProgress(
    userId: 'user-1',
    xp: xp,
    points: xp,
    level: level,
    updatedAt: DateTime(2026, 1, 1),
  );
}

const _badge = GamificationBadge(
  id: 'b-1',
  code: 'first_review',
  name: 'Primeira Avaliação',
  description: 'Publicou sua primeira avaliação.',
);

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

  test('estado inicial é GamificationProfileInitial', () {
    expect(
      container.read(gamificationProfileControllerProvider),
      isA<GamificationProfileInitial>(),
    );
  });

  test('loadForUser sucesso -> GamificationProfileLoaded', () async {
    when(
      () => repository.getProgress('user-1'),
    ).thenAnswer((_) async => _progress());
    when(() => repository.listAllBadges()).thenAnswer((_) async => [_badge]);
    when(() => repository.listEarnedBadges('user-1')).thenAnswer(
      (_) async => [EarnedBadge(badge: _badge, earnedAt: DateTime(2026, 1, 1))],
    );
    when(() => repository.getGroupsActivitySummary('user-1')).thenAnswer(
      (_) async => const GroupsActivitySummary(eventsCount: 5, reviewsCount: 3),
    );

    await container
        .read(gamificationProfileControllerProvider.notifier)
        .loadForUser('user-1');

    final status = container.read(gamificationProfileControllerProvider);
    expect(status, isA<GamificationProfileLoaded>());
    expect(
      (status as GamificationProfileLoaded).earnedBadgeIds,
      contains('b-1'),
    );
    expect(status.groupsActivity.eventsCount, 5);
    expect(status.groupsActivity.reviewsCount, 3);
  });

  test('loadForUser falha -> GamificationProfileError', () async {
    when(
      () => repository.getProgress('user-1'),
    ).thenThrow(const GamificationRepositoryException('Falha.'));

    await container
        .read(gamificationProfileControllerProvider.notifier)
        .loadForUser('user-1');

    expect(
      container.read(gamificationProfileControllerProvider),
      isA<GamificationProfileError>(),
    );
  });
}
