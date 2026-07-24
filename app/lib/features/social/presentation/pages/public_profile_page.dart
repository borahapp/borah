import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/cards/app_card.dart';
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

/// Tela de Perfil público (DV-07 §6), versão mínima aprovada: avatar,
/// nome, bio, seguir/deixar de seguir, links para seguidores/seguindo e
/// avaliações do usuário.
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
      body: profileAsync.when(
        loading: () => const LoadingScreen(),
        error: (error, _) =>
            const Center(child: Text('Não foi possível carregar o perfil.')),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  children: [
                    Center(child: ProfileAvatar(avatarPath: profile.avatarUrl)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      profile.fullName ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(profile.bio!),
                    ],
                    if (!isOwnProfile) ...[
                      const SizedBox(height: AppSpacing.lg),
                      switch (followStatus) {
                        FollowLoaded(:final isFollowing) => AppOutlinedButton(
                          label: isFollowing ? 'Deixar de seguir' : 'Seguir',
                          onPressed: _toggleFollow,
                        ),
                        FollowError(:final message) => Text(message),
                        _ => const LoadingIndicator(size: 36),
                      },
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppTextButton(
                          label: 'Seguidores',
                          onPressed: () =>
                              context.push('/users/${widget.userId}/followers'),
                        ),
                        AppTextButton(
                          label: 'Seguindo',
                          onPressed: () =>
                              context.push('/users/${widget.userId}/following'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Avaliações'),
              const SizedBox(height: AppSpacing.sm),
              switch (reviewsStatus) {
                ReviewsInitial() ||
                ReviewsLoading() => const LoadingIndicator(size: 36),
                ReviewsError(:final message) => Text(message),
                ReviewsEmpty() => const Text('Nenhuma avaliação ainda.'),
                ReviewsLoaded(:final result) => Column(
                  children: result.items
                      .map(
                        (review) => ReviewSummaryTile(
                          review: review,
                          contentPadding: EdgeInsets.zero,
                          onTap: () => context.push('/reviews/${review.id}'),
                        ),
                      )
                      .toList(),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
