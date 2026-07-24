import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
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
      body: switch (status) {
        ProfileInitial() || ProfileLoading() => const LoadingScreen(),
        ProfileError(:final message) => Center(child: Text(message)),
        ProfileLoaded(:final profile) ||
        ProfileUpdating(:final profile) ||
        ProfileUpdateSuccess(:final profile) => _ProfileView(
          avatarPath: profile.avatarUrl,
          fullName: profile.fullName,
          bio: profile.bio,
          city: profile.city,
          state: profile.state,
          createdAt: profile.createdAt,
        ),
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
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
        ],
      ),
    );
  }
}
