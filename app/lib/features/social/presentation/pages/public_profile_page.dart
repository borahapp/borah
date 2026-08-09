import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../reviews/presentation/states/reviews_status.dart';
import '../../../reviews/presentation/widgets/review_summary_tile.dart';
import '../../../users/presentation/widgets/profile_avatar.dart';
import '../../application/follow_controller.dart';
import '../../application/public_profile_provider.dart';
import '../../application/user_reviews_controller.dart';
import '../../presentation/states/follow_status.dart';

/// Tela de Perfil público (FASE SOCIAL 2) - avatar, nome, `@username`,
/// bio, seguidores/seguindo (contadores reais), seguir/deixar de
/// seguir, nível/XP/badges (reaproveita `GamificationRepository`, sem
/// migration nova - ver AUDITORIA — FASE SOCIAL 2 §7/§9), grupos em
/// comum (quando houver) e as avaliações públicas do usuário (mesma
/// fonte já usada antes da fase, sem `activities` novo).
class PublicProfilePage extends ConsumerStatefulWidget {
  const PublicProfilePage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId != null) {
        ref
            .read(followControllerProvider.notifier)
            .load(currentUserId, widget.userId);
      }
      ref
          .read(userReviewsControllerProvider.notifier)
          .loadForUser(widget.userId);
    });
  }

  void _toggleFollow() {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;
    ref
        .read(followControllerProvider.notifier)
        .toggle(currentUserId, widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(publicProfileProvider(widget.userId));
    final followStatus = ref.watch(followControllerProvider);
    final reviewsStatus = ref.watch(userReviewsControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: const AppTopBar(title: 'Perfil'),
      body: AppAnimatedSwitcher(
        child: profileAsync.when(
          loading: () => const LoadingScreen(key: ValueKey('loading')),
          error: (error, _) => const Center(
            key: ValueKey('error'),
            child: Text('Não foi possível carregar o perfil.'),
          ),
          data: (profile) => SingleChildScrollView(
            key: const ValueKey('loaded'),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Center(
                        child: ProfileAvatar(avatarPath: profile.avatarUrl),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        profile.fullName?.isNotEmpty == true
                            ? profile.fullName!
                            : 'Sem nome',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (profile.username != null &&
                          profile.username!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '@${profile.username}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(profile.bio!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppTextButton(
                            label: '${profile.followersCount} seguidores',
                            onPressed: () => context.push(
                              '/users/${widget.userId}/followers',
                            ),
                          ),
                          AppTextButton(
                            label: '${profile.followingCount} seguindo',
                            onPressed: () => context.push(
                              '/users/${widget.userId}/following',
                            ),
                          ),
                        ],
                      ),
                      if (!isOwnProfile) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppAnimatedSwitcher(
                          child: switch (followStatus) {
                            FollowLoaded(:final isFollowing) =>
                              AppOutlinedButton(
                                key: const ValueKey('follow-loaded'),
                                label: isFollowing
                                    ? 'Deixar de seguir'
                                    : 'Seguir',
                                onPressed: _toggleFollow,
                              ),
                            FollowError(:final message) => Text(
                              message,
                              key: const ValueKey('follow-error'),
                            ),
                            _ => const LoadingIndicator(
                              key: ValueKey('follow-loading'),
                              size: 36,
                            ),
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _GamificationSection(userId: widget.userId),
                _CommonGroupsSection(userId: widget.userId),
                const SectionHeader(title: 'Avaliações'),
                const SizedBox(height: AppSpacing.sm),
                AppAnimatedSwitcher(
                  child: switch (reviewsStatus) {
                    ReviewsInitial() ||
                    ReviewsLoading() => const LoadingIndicator(
                      key: ValueKey('reviews-loading'),
                      size: 36,
                    ),
                    ReviewsError(:final message) => Text(
                      message,
                      key: const ValueKey('reviews-error'),
                    ),
                    ReviewsEmpty() => const Text(
                      'Nenhuma avaliação ainda.',
                      key: ValueKey('reviews-empty'),
                    ),
                    ReviewsLoaded(:final result) => Column(
                      key: const ValueKey('reviews-loaded'),
                      children: result.items.indexed
                          .map(
                            (entry) => AppStaggeredListItem(
                              index: entry.$1,
                              child: ReviewSummaryTile(
                                review: entry.$2,
                                contentPadding: EdgeInsets.zero,
                                onTap: () =>
                                    context.push('/reviews/${entry.$2.id}'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nível/XP/badges (FASE SOCIAL 2 §7/§9 da AUDITORIA) - só os badges já
/// conquistados são exibidos aqui (lista completa com bloqueados
/// continua sendo `GamificationProfilePage`, exclusiva do próprio
/// usuário).
class _GamificationSection extends ConsumerWidget {
  const _GamificationSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicProfileGamificationProvider(userId));
    final theme = Theme.of(context);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: LoadingIndicator(size: 28)),
      ),
      error: (error, _) => const SizedBox.shrink(),
      data: (gamification) {
        final earnedBadges = gamification.allBadges
            .where((badge) => gamification.earnedBadgeIds.contains(badge.id))
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nível ${gamification.progress.level}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${gamification.progress.xp} XP',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Badges', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                if (earnedBadges.isEmpty)
                  const Text('Nenhum badge conquistado ainda.')
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: earnedBadges
                        .map(
                          (badge) => AppBadge(
                            label: badge.name,
                            icon: Icons.emoji_events,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Grupos em comum (FASE SOCIAL 2 §7/§13 da AUDITORIA) - só aparece
/// quando há pelo menos 1 grupo em comum ("se houver", pedido
/// explícito).
class _CommonGroupsSection extends ConsumerWidget {
  const _CommonGroupsSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicProfileCommonGroupsProvider(userId));

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Grupos em comum'),
              const SizedBox(height: AppSpacing.sm),
              ...groups.map(
                (group) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.groups_outlined),
                  title: Text(group.name),
                  onTap: () => context.push('/groups/${group.id}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
