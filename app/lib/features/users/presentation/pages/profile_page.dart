import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../gamification/application/gamification_profile_controller.dart';
import '../../../gamification/presentation/states/gamification_profile_status.dart';
import '../../application/user_profile_controller.dart';
import '../states/user_profile_status.dart';
import '../widgets/profile_avatar.dart';

/// Tela de visualização de perfil (DV-02 §6). Mostra os campos que o
/// DV-02 modela (§9) e, RC-03 F09, atalhos com prévia de dado real
/// (nível/XP em "Gamificação", achado do wireframe UX-02 §14 e do Design
/// Gap §1.4 - substitui os `ListTile` neutros por `AppCard`, mesmo padrão
/// já usado em `RestaurantCard`/`RankingCard`).
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.read(userProfileControllerProvider.notifier).loadProfile(userId);
        ref
            .read(gamificationProfileControllerProvider.notifier)
            .loadForUser(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(userProfileControllerProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Perfil',
        actions: [
          AppIconButton(
            icon: Icons.settings,
            tooltip: 'Configurações',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          ProfileInitial() ||
          ProfileLoading() => const LoadingScreen(key: ValueKey('loading')),
          ProfileError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null) return;
              ref
                  .read(userProfileControllerProvider.notifier)
                  .loadProfile(userId);
            },
          ),
          ProfileLoaded(:final profile) ||
          ProfileUpdating(:final profile) ||
          ProfileUpdateSuccess(:final profile) => _ProfileView(
            key: const ValueKey('loaded'),
            userId: profile.id,
            avatarPath: profile.avatarUrl,
            fullName: profile.fullName,
            username: profile.username,
            bio: profile.bio,
            city: profile.city,
            state: profile.state,
            followersCount: profile.followersCount,
            followingCount: profile.followingCount,
            createdAt: profile.createdAt,
          ),
        },
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({
    super.key,
    required this.userId,
    required this.avatarPath,
    required this.fullName,
    required this.username,
    required this.bio,
    required this.city,
    required this.state,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
  });

  final String userId;
  final String? avatarPath;
  final String? fullName;
  final String? username;
  final String? bio;
  final String? city;
  final String? state;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = [
      if (city != null && city!.isNotEmpty) city,
      if (state != null && state!.isNotEmpty) state,
    ].join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          ProfileAvatar(avatarPath: avatarPath, radius: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(
            fullName?.isNotEmpty == true ? fullName! : 'Sem nome',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (username != null && username!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('@$username', style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(location, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (bio != null && bio!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(bio!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSpacing.lg),
          // FASE SOCIAL 2 - contadores reais (profiles.followers_count/
          // following_count, mantidos por trigger - ver AUDITORIA §4),
          // mesmas rotas de FollowListPage já usadas pelo Perfil público.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppTextButton(
                label: '$followersCount seguidores',
                onPressed: () => context.push('/users/$userId/followers'),
              ),
              AppTextButton(
                label: '$followingCount seguindo',
                onPressed: () => context.push('/users/$userId/following'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppOutlinedButton(
            label: 'Editar perfil',
            onPressed: () => context.push('/profile/edit'),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildShortcuts(context, ref),
        ],
      ),
    );
  }

  /// RC-03 F09 - grade 2x2 de `AppCard` (substitui os `ListTile` neutros
  /// dos comentários RC-04E/Sprint 0 anteriores, mesma lista de destinos,
  /// nenhuma rota nova). "Gamificação" ganha prévia real de nível/XP
  /// quando `GamificationProfileController` já carregou (achado do
  /// `BORAH_NEXT_STEP_ANALYSIS.md §1`: o XP já é concedido de verdade
  /// desde a Sprint 0, mas nenhuma tela fora de `gamification_profile_page`
  /// contava essa história de volta para o usuário).
  Widget _buildShortcuts(BuildContext context, WidgetRef ref) {
    final gamificationStatus = ref.watch(gamificationProfileControllerProvider);
    final progress = switch (gamificationStatus) {
      GamificationProfileLoaded(:final progress) => progress,
      _ => null,
    };

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.3,
      children: [
        _ShortcutCard(
          icon: Icons.dynamic_feed_outlined,
          label: 'Feed',
          onTap: () => context.push('/feed'),
        ),
        _ShortcutCard(
          icon: Icons.emoji_events_outlined,
          label: 'Gamificação',
          preview: progress == null
              ? null
              : 'Nível ${progress.level} · ${progress.xp} XP',
          onTap: () => context.push('/gamification'),
        ),
        _ShortcutCard(
          icon: Icons.leaderboard_outlined,
          label: 'Rankings',
          onTap: () => context.push('/rankings'),
        ),
        // FASE SOCIAL 4: "Grupos" saiu da barra de navegação principal
        // (deu lugar a "Explorar") - este atalho é o novo lar de "Meus
        // Grupos", mesma rota `/groups`/`GroupsListPage` de sempre,
        // nenhum dado ou comportamento alterado.
        _ShortcutCard(
          icon: Icons.groups_outlined,
          label: 'Meus Grupos',
          onTap: () => context.push('/groups'),
        ),
        _ShortcutCard(
          icon: Icons.notifications_outlined,
          label: 'Notificações',
          onTap: () => context.push('/notifications'),
        ),
        // FASE SOCIAL 1: Favoritos saiu da barra de navegação principal
        // (deu lugar a Rankings) - este atalho é o novo lar da
        // funcionalidade, mesma rota `/favorites` já existente, nenhum
        // dado ou comportamento alterado.
        _ShortcutCard(
          icon: Icons.favorite_border,
          label: 'Favoritos',
          onTap: () => context.push('/favorites'),
        ),
      ],
    );
  }
}

/// Atalho do Perfil (RC-03 F09) - ícone + rótulo, com uma linha de
/// prévia de dado opcional (ex.: "Nível 3 · 420 XP"). Local a esta tela
/// (não vira componente de design system porque nenhuma outra tela do
/// app usa este layout específico de "grade de atalhos").
class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.preview,
  });

  final IconData icon;
  final String label;
  final String? preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: theme.textTheme.titleSmall),
          if (preview != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              preview!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
