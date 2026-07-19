import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(title: const Text('Perfil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('Não foi possível carregar o perfil.')),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: ProfileAvatar(avatarPath: profile.avatarUrl)),
              const SizedBox(height: 16),
              Text(
                profile.fullName ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(profile.bio!),
              ],
              if (!isOwnProfile) ...[
                const SizedBox(height: 16),
                switch (followStatus) {
                  FollowLoaded(:final isFollowing) => OutlinedButton(
                    onPressed: _toggleFollow,
                    child: Text(isFollowing ? 'Deixar de seguir' : 'Seguir'),
                  ),
                  FollowError(:final message) => Text(message),
                  _ => const SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                },
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        context.push('/users/${widget.userId}/followers'),
                    child: const Text('Seguidores'),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push('/users/${widget.userId}/following'),
                    child: const Text('Seguindo'),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                'Avaliações',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              switch (reviewsStatus) {
                ReviewsInitial() || ReviewsLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
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
