import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/user_profile_controller.dart';
import '../states/user_profile_status.dart';
import '../widgets/profile_avatar.dart';

/// Tela de visualização de perfil (DV-02 §6). Mostra apenas os campos que
/// o DV-02 realmente modela (§9) — Nível/XP/Badges/Estatísticas do
/// wireframe UX-02 §14 pertencem a outros módulos (DV-04/05/10) e não são
/// exibidos aqui.
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
            avatarPath: profile.avatarUrl,
            fullName: profile.fullName,
            bio: profile.bio,
            city: profile.city,
            state: profile.state,
            createdAt: profile.createdAt,
          ),
        },
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    super.key,
    required this.avatarPath,
    required this.fullName,
    required this.bio,
    required this.city,
    required this.state,
    required this.createdAt,
  });

  final String? avatarPath;
  final String? fullName;
  final String? bio;
  final String? city;
  final String? state;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
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
          if (location.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(location, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (bio != null && bio!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(bio!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppOutlinedButton(
            label: 'Editar perfil',
            onPressed: () => context.push('/profile/edit'),
          ),
          const SizedBox(height: AppSpacing.xl),
          // RC-04E: acesso rápido a telas já existentes que, antes desta
          // rodada, só eram alcançáveis pelo antigo placeholder de
          // desenvolvedor em `/home` - mesmo padrão de `ListTile` já usado
          // em `SettingsPage`.
          //
          // RC-03 Sprint 0 (F24): a rota `/feed` (FeedPage) existia e
          // funcionava, mas nenhuma tela do app navegava até ela - achado
          // confirmado por busca em todo `lib/` (RC03_UX_AUDIT.md §2.11).
          // Este é o ponto de entrada adicionado, seguindo o mesmo padrão
          // dos 3 atalhos já existentes neste Card.
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dynamic_feed_outlined),
                  title: const Text('Feed'),
                  onTap: () => context.push('/feed'),
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Gamificação'),
                  onTap: () => context.push('/gamification'),
                ),
                ListTile(
                  leading: const Icon(Icons.leaderboard_outlined),
                  title: const Text('Rankings'),
                  onTap: () => context.push('/rankings'),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notificações'),
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
