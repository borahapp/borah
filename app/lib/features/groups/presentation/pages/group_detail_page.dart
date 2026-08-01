import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../users/presentation/widgets/profile_avatar.dart';
import '../../application/group_detail_controller.dart';
import '../../domain/group_details.dart';
import '../states/group_detail_status.dart';

/// Tela de Detalhe do Grupo (GROUP-02B.1) - substitui por completo o
/// placeholder do GROUP-02B.0. Nome/descrição/código de convite +
/// compartilhar + lista de membros (avatar/nome/papel em PT-BR). Sem
/// promover/remover membro, editar grupo ou sair do grupo - fora do
/// escopo desta sprint.
class GroupDetailPage extends ConsumerStatefulWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupDetailControllerProvider.notifier).load(widget.groupId);
    });
  }

  /// A página só dispara a ação de compartilhamento nativo - o texto é
  /// preparado pelo controller (`buildInviteShareMessage`), não aqui.
  void _shareInviteCode() {
    final message = ref
        .read(groupDetailControllerProvider.notifier)
        .buildInviteShareMessage();
    if (message == null) return;
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(groupDetailControllerProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Grupo',
        actions: [
          AppIconButton(
            icon: Icons.event_outlined,
            tooltip: 'Rolês',
            // ROLÊ-03: passa a abrir a lista de rolês do grupo (não mais
            // a criação direto) - a lista é o ponto central da
            // funcionalidade, com seu próprio "+" para criar
            // (`EventsListPage`, decisão de produto aprovada).
            onPressed: () => context.push('/groups/${widget.groupId}/events'),
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          GroupDetailInitial() ||
          GroupDetailLoading() => const LoadingScreen(
            key: ValueKey('loading'),
          ),
          GroupDetailError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref
                .read(groupDetailControllerProvider.notifier)
                .load(widget.groupId),
          ),
          GroupDetailLoaded(:final details) => _GroupDetailContent(
            key: const ValueKey('loaded'),
            details: details,
            onShare: _shareInviteCode,
          ),
        },
      ),
    );
  }
}

class _GroupDetailContent extends StatelessWidget {
  const _GroupDetailContent({
    super.key,
    required this.details,
    required this.onShare,
  });

  final GroupDetails details;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = details.group;
    final members = details.members;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: theme.textTheme.headlineSmall),
          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(group.description!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Código do convite', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            group.inviteCode,
            style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 4),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(label: 'Compartilhar', onPressed: onShare),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Membros'),
          const SizedBox(height: AppSpacing.sm),
          ...members.indexed.map(
            (entry) => AppStaggeredListItem(
              index: entry.$1,
              child: ListTile(
                leading: ProfileAvatar(
                  avatarPath: entry.$2.avatarUrl,
                  radius: 20,
                ),
                title: Text(entry.$2.fullName ?? ''),
                trailing: AppBadge(label: entry.$2.roleLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
