import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/groups_activity_summary.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
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

class MockReviewRepository extends Mock implements ReviewRepository {}

UserProfile _profile() {
  return UserProfile(
    id: 'user-1',
    fullName: 'Ana Silva',
    username: 'anasilva',
    bio: null,
    avatarUrl: null,
    city: 'São Paulo',
    state: 'SP',
    followersCount: 5,
    followingCount: 2,
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
  MockReviewRepository reviewRepository,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: '/gamification',
        builder: (_, _) => const Scaffold(body: Text('Gamification Page')),
      ),
      GoRoute(
        path: '/favorites',
        builder: (_, _) => const Scaffold(body: Text('Favorites Page')),
      ),
      GoRoute(
        path: '/groups',
        builder: (_, _) => const Scaffold(body: Text('Groups Page')),
      ),
      GoRoute(
        path: '/users/:id/followers',
        builder: (_, _) => const Scaffold(body: Text('Followers Page')),
      ),
      GoRoute(
        path: '/users/:id/following',
        builder: (_, _) => const Scaffold(body: Text('Following Page')),
      ),
      // Rodada "perfil individual como centro" (pós-FASE 09) - destino
      // do novo atalho "X avaliações" (reaproveita o Perfil Público).
      GoRoute(
        path: '/users/:id',
        builder: (_, state) => Scaffold(
          body: Text('Public Profile Page ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userProfileRepositoryProvider.overrideWithValue(profileRepository),
      gamificationRepositoryProvider.overrideWithValue(gamificationRepository),
      reviewRepositoryProvider.overrideWithValue(reviewRepository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockUserProfileRepository profileRepository;
  late MockGamificationRepository gamificationRepository;
  late MockReviewRepository reviewRepository;

  setUp(() {
    profileRepository = MockUserProfileRepository();
    gamificationRepository = MockGamificationRepository();
    reviewRepository = MockReviewRepository();

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
    // Padrão: 0 avaliações - os testes que precisam de outro valor
    // sobrescrevem no corpo do teste (roda depois do setUp).
    when(
      () => reviewRepository.countByUser('user-1'),
    ).thenAnswer((_) async => 0);
    // Padrão: sem fotos - os testes que precisam de outro valor
    // sobrescrevem no corpo do teste (roda depois do setUp).
    when(
      () => reviewRepository.listUserPhotos('user-1'),
    ).thenAnswer((_) async => []);
  });

  testWidgets('mostra username e contadores de seguidores/seguindo', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository, reviewRepository));
    await tester.pumpAndSettle();

    expect(find.text('@anasilva'), findsOneWidget);
    expect(find.text('5 seguidores'), findsOneWidget);
    expect(find.text('2 seguindo'), findsOneWidget);
  });

  group('contador de avaliações (rodada "perfil individual como centro", '
      'pós-FASE 09)', () {
    testWidgets('mostra a quantidade de restaurantes avaliados', (
      tester,
    ) async {
      when(
        () => reviewRepository.countByUser('user-1'),
      ).thenAnswer((_) async => 7);

      await tester.pumpWidget(
        _wrap(profileRepository, gamificationRepository, reviewRepository),
      );
      await tester.pumpAndSettle();

      expect(find.text('7 avaliações'), findsOneWidget);
    });

    testWidgets('com exatamente 1 avaliação, usa o singular', (tester) async {
      when(
        () => reviewRepository.countByUser('user-1'),
      ).thenAnswer((_) async => 1);

      await tester.pumpWidget(
        _wrap(profileRepository, gamificationRepository, reviewRepository),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 avaliação'), findsOneWidget);
    });

    testWidgets(
      'tocar no contador navega para o próprio perfil público (lista '
      'completa de avaliações)',
      (tester) async {
        when(
          () => reviewRepository.countByUser('user-1'),
        ).thenAnswer((_) async => 7);

        await tester.pumpWidget(
          _wrap(profileRepository, gamificationRepository, reviewRepository),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('7 avaliações'));
        await tester.pumpAndSettle();

        expect(find.text('Public Profile Page user-1'), findsOneWidget);
      },
    );
  });

  group(
    'grade de fotos (rodada "perfil individual como centro", '
    'pós-FASE 09)',
    () {
      testWidgets('sem fotos, não mostra a seção "Fotos"', (tester) async {
        await tester.pumpWidget(
          _wrap(profileRepository, gamificationRepository, reviewRepository),
        );
        await tester.pumpAndSettle();

        expect(find.text('Fotos'), findsNothing);
      });

      testWidgets('com fotos, mostra a seção "Fotos" com uma miniatura '
          'por URL', (tester) async {
        when(() => reviewRepository.listUserPhotos('user-1')).thenAnswer(
          (_) async => ['https://x/photo-1.jpg', 'https://x/photo-2.jpg'],
        );

        await tester.pumpWidget(
          _wrap(profileRepository, gamificationRepository, reviewRepository),
        );
        await tester.pumpAndSettle();
        while (tester.takeException() != null) {}

        expect(find.text('Fotos'), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(2));
      });
    },
  );

  testWidgets('tocar em seguidores navega até a lista de seguidores', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository, reviewRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5 seguidores'));
    await tester.pumpAndSettle();

    expect(find.text('Followers Page'), findsOneWidget);
  });

  testWidgets('tocar em seguindo navega até a lista de seguindo', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository, reviewRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2 seguindo'));
    await tester.pumpAndSettle();

    expect(find.text('Following Page'), findsOneWidget);
  });

  testWidgets('mostra os 6 atalhos', (tester) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository, reviewRepository));
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Gamificação'), findsOneWidget);
    expect(find.text('Ranking de avaliadores'), findsOneWidget);
    expect(find.text('Meus Grupos'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
  });

  testWidgets(
    'tocar no atalho de Meus Grupos navega até a rota (FASE SOCIAL 4 - '
    '"Grupos" saiu da barra principal)',
    (tester) async {
      await tester.pumpWidget(_wrap(profileRepository, gamificationRepository, reviewRepository));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Meus Grupos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meus Grupos'));
      await tester.pumpAndSettle();

      expect(find.text('Groups Page'), findsOneWidget);
    },
  );

  testWidgets('tocar no atalho de Favoritos navega até a rota', (tester) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository, reviewRepository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Favoritos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('Favorites Page'), findsOneWidget);
  });

  testWidgets('atalho de Gamificação mostra prévia de nível/XP', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository, reviewRepository));
    await tester.pumpAndSettle();

    expect(find.text('Nível 3 · 420 XP'), findsOneWidget);
  });

  testWidgets('tocar no atalho de Gamificação navega até a rota', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(profileRepository, gamificationRepository, reviewRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gamificação'));
    await tester.pumpAndSettle();

    expect(find.text('Gamification Page'), findsOneWidget);
  });
}
