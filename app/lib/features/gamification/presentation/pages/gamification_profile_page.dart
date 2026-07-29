import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_animated_fraction.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_pulse_icon.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_gradients.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
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
      appBar: AppTopBar(
        title: 'Gamificação',
        actions: [
          AppIconButton(
            icon: Icons.leaderboard,
            tooltip: 'Ranking de usuários',
            onPressed: () => context.push('/gamification/ranking'),
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          GamificationProfileInitial() || GamificationProfileLoading() =>
            const LoadingScreen(key: ValueKey('loading')),
          GamificationProfileError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null) return;
              ref
                  .read(gamificationProfileControllerProvider.notifier)
                  .loadForUser(userId);
            },
          ),
          GamificationProfileLoaded(
            :final progress,
            :final allBadges,
            :final earnedBadgeIds,
          ) =>
            _ProfileView(
              key: const ValueKey('loaded'),
              progress: progress,
              allBadges: allBadges,
              earnedBadgeIds: earnedBadgeIds,
            ),
        },
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    super.key,
    required this.progress,
    required this.allBadges,
    required this.earnedBadgeIds,
  });

  final UserProgress progress;
  final List<GamificationBadge> allBadges;
  final Set<String> earnedBadgeIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradients = AppGradients.of(context);

    final currentThreshold = UserProgress.levelThresholds[progress.level] ?? 0;
    final nextThreshold = UserProgress.levelThresholds[progress.level + 1];
    final progressToNextLevel = nextThreshold == null
        ? 1.0
        : (progress.xp - currentThreshold) / (nextThreshold - currentThreshold);
    final xpToNext = nextThreshold == null ? null : nextThreshold - progress.xp;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.inverseSurface,
            borderRadius: AppRadius.radiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nível ${progress.level}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onInverseSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${progress.xp} XP · ${progress.points} pontos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onInverseSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: AppRadius.radiusPill,
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(
                        color: scheme.onInverseSurface.withValues(alpha: 0.25),
                      ),
                      AppAnimatedFraction(
                        value: progressToNextLevel,
                        child: DecoratedBox(
                          decoration: BoxDecoration(gradient: gradients.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (xpToNext != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$xpToNext XP para o próximo nível',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.tertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Conquistas', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ...allBadges.map((badge) {
          final earned = earnedBadgeIds.contains(badge.id);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              earned ? Icons.emoji_events : Icons.emoji_events_outlined,
            ),
            title: Text(badge.name),
            subtitle: Text(badge.description ?? ''),
            trailing: AppPulseIcon(
              trigger: earned,
              child: AppBadge(
                label: earned ? 'Conquistado' : 'Bloqueado',
                earned: earned,
              ),
            ),
          );
        }),
      ],
    );
  }
}
