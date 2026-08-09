import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/groups_activity_summary.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:app/features/users/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

UserProfile _profile() {
  return UserProfile(
    id: 'user-1',
    fullName: 'Ana Silva',
    bio: null,
    avatarUrl: null,
    city: 'São Paulo',
    state: 'SP',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

UserProgress _progress({int level = 3, int xp = 420}) {
  return UserProgress(
    userId: 'user-1',
    xp: xp,
    points: xp,
    level: level,
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  MockUserProfileRepository profileRepository,
  MockGamificationRepository gamificationRepository,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: '/gamification',
        builder: (_, _) => const Scaffold(body: Text('Gamification Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userProfileRepositoryProvider.overrideWithValue(profileRepository),
      gamificationRepositoryProvider.overrideWithValue(gamificationRepository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockUserProfileRepository profileRepository;
  late MockGamificationRepository gamificationRepository;

  setUp(() {
    profileRepository = MockUserProfileRepository();
    gamificationRepository = MockGamificationRepository();

    when(
      () => profileRepository.getProfile('user-1'),
    ).thenAnswer((_) async => _profile());
    when(
      () => gamificationRepository.getProgress('user-1'),
    ).thenAnswer((_) async => _progress());
    when(
      () => gamificationRepository.listAllBadges(),
    ).thenAnswer((_) async => []);
    when(
      () => gamificationRepository.listEarnedBadges('user-1'),
    ).thenAnswer((_) async => []);
    when(
      () => gamificationRepository.getGroupsActivitySummary('user-1'),
    ).thenAnswer(
      (_) async => const GroupsActivitySummary(eventsCount: 0, reviewsCount: 0),
    );
  });

  testWidgets('mostra os 4 atalhos', (tester) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository));
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Gamificação'), findsOneWidget);
    expect(find.text('Rankings'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);
  });

  testWidgets('atalho de Gamificação mostra prévia de nível/XP', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository));
    await tester.pumpAndSettle();

    expect(find.text('Nível 3 · 420 XP'), findsOneWidget);
  });

  testWidgets('tocar no atalho de Gamificação navega até a rota', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gamificação'));
    await tester.pumpAndSettle();

    expect(find.text('Gamification Page'), findsOneWidget);
  });
}
