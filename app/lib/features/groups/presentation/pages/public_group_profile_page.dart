import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/avatars/user_avatar.dart';
import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/join_group_controller.dart';
import '../../application/public_group_profile_provider.dart';
import '../states/join_group_status.dart';

/// Perfil público de um grupo `public` (FASE SOCIAL 3) - destino de
/// quem encontrou o grupo na Busca/Explorar e ainda não é membro.
/// Mesma filosofia visual de `PublicProfilePage` (pessoas): `AppCard`
/// central com avatar/nome/descrição, badge de status, botão de ação.
///
/// Deliberadamente sem lista de membros, atividade, ranking ou
/// memórias - decisão de produto da fase: não-membro só vê dados
/// básicos (nome/foto/descrição/contagem de membros). Tudo isso só
/// aparece depois de entrar, na `GroupDetailPage` normal (rota
/// diferente, `/groups/:id` - esta tela assume que o visitante ainda
/// não é membro).
class PublicGroupProfilePage extends ConsumerWidget {
  const PublicGroupProfilePage({super.key, required this.groupId});

  final String groupId;

  Future<void> _join(WidgetRef ref) {
    return ref.read(joinGroupControllerProvider.notifier).joinPublic(groupId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(publicGroupSummaryProvider(groupId));
    final joinStatus = ref.watch(joinGroupControllerProvider);

    ref.listen<JoinGroupStatus>(joinGroupControllerProvider, (previous, next) {
      if (next is JoinGroupSaveSuccess) {
        // FASE SOCIAL 3: mesmo padrão UX-01 de CreateGroupPage - vai
        // direto para o Detalhe do grupo (agora o usuário já é membro),
        // não fecha de volta para a busca.
        context.pushReplacement('/groups/${next.group.id}');
      } else if (next is JoinGroupError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Grupo'),
      body: AppAnimatedSwitcher(
        child: groupAsync.when(
          loading: () => const LoadingScreen(key: ValueKey('loading')),
          error: (error, _) => const Center(
            key: ValueKey('error'),
            child: Text('Não foi possível carregar o grupo.'),
          ),
          data: (group) {
            final memberCount = group.memberCount ?? 0;
            final memberLabel = memberCount == 1
                ? '1 membro'
                : '$memberCount membros';

            return Padding(
              key: const ValueKey('loaded'),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppCard(
                child: Column(
                  children: [
                    UserAvatar(
                      imageUrl: group.photoUrl,
                      radius: 40,
                      fallbackIcon: Icons.groups,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppBadge(label: 'Público'),
                    if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(group.description!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      memberLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppPrimaryButton(
                      label: 'Entrar',
                      isLoading: joinStatus is JoinGroupSaving,
                      onPressed: () => _join(ref),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
