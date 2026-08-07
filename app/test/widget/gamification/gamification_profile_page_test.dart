import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/gamification/data/gamification_repository_impl.dart';
import 'package:app/features/gamification/domain/gamification_repository.dart';
import 'package:app/features/gamification/domain/groups_activity_summary.dart';
import 'package:app/features/gamification/domain/user_progress.dart';
import 'package:app/features/gamification/presentation/pages/gamification_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

UserProgress _progress({int xp = 0, int level = 1}) {
  return UserProgress(
    userId: 'user-1',
    xp: xp,
    points: xp,
    level: level,
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(MockGamificationRepository repository) {
  return ProviderScope(
    overrides: [
      gamificationRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: const MaterialApp(home: GamificationProfilePage()),
  );
}

void main() {
  late MockGamificationRepository repository;

  setUp(() {
    repository = MockGamificationRepository();
    when(() => repository.listAllBadges()).thenAnswer((_) async => const []);
    when(
      () => repository.listEarnedBadges('user-1'),
    ).thenAnswer((_) async => const []);
  });

  testWidgets(
    'mostra "XP de rolês" com os totais e o XP calculado (FASE B, Entrega 4)',
    (tester) async {
      when(
        () => repository.getProgress('user-1'),
      ).thenAnswer((_) async => _progress());
      when(() => repository.getGroupsActivitySummary('user-1')).thenAnswer(
        (_) async =>
            const GroupsActivitySummary(eventsCount: 3, reviewsCount: 2),
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('XP de rolês'), findsOneWidget);
      expect(find.text('Rolês confirmados'), findsOneWidget);
      expect(find.text('Avaliações coletivas'), findsOneWidget);
      expect(find.text('XP ganho em rolês'), findsOneWidget);
      // 3 rolês x 20 XP + 2 avaliações x 40 XP = 140 XP.
      expect(find.text('140 XP'), findsOneWidget);
    },
  );

  testWidgets('sem nenhum grupo/rolê, mostra 0 XP sem quebrar', (tester) async {
    when(
      () => repository.getProgress('user-1'),
    ).thenAnswer((_) async => _progress());
    when(() => repository.getGroupsActivitySummary('user-1')).thenAnswer(
      (_) async => const GroupsActivitySummary(eventsCount: 0, reviewsCount: 0),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('XP de rolês'), findsOneWidget);
    expect(find.text('0 XP'), findsOneWidget);
  });

  testWidgets(
    'seção de Conquistas continua presente e inalterada junto da seção nova',
    (tester) async {
      when(
        () => repository.getProgress('user-1'),
      ).thenAnswer((_) async => _progress(xp: 40));
      when(() => repository.getGroupsActivitySummary('user-1')).thenAnswer(
        (_) async =>
            const GroupsActivitySummary(eventsCount: 1, reviewsCount: 1),
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Nível 1'), findsOneWidget);
      expect(find.text('Conquistas'), findsOneWidget);
      expect(find.text('XP de rolês'), findsOneWidget);
    },
  );
}
