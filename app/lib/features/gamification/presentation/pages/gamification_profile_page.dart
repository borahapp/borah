import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/application/auth_controller.dart';
import '../../application/gamification_profile_controller.dart';
import '../../domain/gamification_badge.dart';
import '../../domain/user_progress.dart';
import '../states/gamification_profile_status.dart';

/// Tela unificada de Perfil de Gamificação + Conquistas + Badges (DV-10
/// §6) - o próprio usuário logado, sem visualização de perfis alheios
/// (não pedido pelo DV-10).
class GamificationProfilePage extends ConsumerStatefulWidget {
  const GamificationProfilePage({super.key});

  @override
  ConsumerState<GamificationProfilePage> createState() =>
      _GamificationProfilePageState();
}

class _GamificationProfilePageState
    extends ConsumerState<GamificationProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      ref
          .read(gamificationProfileControllerProvider.notifier)
          .loadForUser(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(gamificationProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamificação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.push('/gamification/ranking'),
          ),
        ],
      ),
      body: switch (status) {
        GamificationProfileInitial() || GamificationProfileLoading() =>
          const Center(child: CircularProgressIndicator()),
        GamificationProfileError(:final message) => Center(
          child: Text(message),
        ),
        GamificationProfileLoaded(
          :final progress,
          :final allBadges,
          :final earnedBadgeIds,
        ) =>
          _ProfileView(
            progress: progress,
            allBadges: allBadges,
            earnedBadgeIds: earnedBadgeIds,
          ),
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.progress,
    required this.allBadges,
    required this.earnedBadgeIds,
  });

  final UserProgress progress;
  final List<GamificationBadge> allBadges;
  final Set<String> earnedBadgeIds;

  @override
  Widget build(BuildContext context) {
    final currentThreshold = UserProgress.levelThresholds[progress.level] ?? 0;
    final nextThreshold = UserProgress.levelThresholds[progress.level + 1];
    final progressToNextLevel = nextThreshold == null
        ? 1.0
        : (progress.xp - currentThreshold) / (nextThreshold - currentThreshold);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Nível ${progress.level}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('${progress.xp} XP · ${progress.points} pontos'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progressToNextLevel.clamp(0.0, 1.0)),
        const SizedBox(height: 24),
        Text('Badges', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...allBadges.map((badge) {
          final earned = earnedBadgeIds.contains(badge.id);
          return ListTile(
            leading: Icon(
              earned ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: earned ? Colors.amber : null,
            ),
            title: Text(badge.name),
            subtitle: Text(badge.description ?? ''),
          );
        }),
      ],
    );
  }
}
