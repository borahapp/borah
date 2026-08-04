import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/dialogs/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../users/presentation/widgets/profile_avatar.dart';
import '../../application/group_detail_controller.dart';
import '../../application/groups_list_controller.dart';
import '../../domain/group.dart';
import '../../domain/group_details.dart';
import '../../domain/group_member.dart';
import '../../domain/group_repository.dart';
import '../states/group_detail_status.dart';

/// Tela de Detalhe do Grupo (GROUP-02B.1; administração adicionada no
/// BLOCO 2). Nome/descrição/código de convite + compartilhar + lista de
/// membros. Promover/rebaixar/remover membro (admin/owner) e editar
/// grupo (admin/owner) ficam por linha/ícone condicionados ao papel do
/// usuário atual (`GroupDetails.ownRole`) - transferência de
/// propriedade continua fora do escopo (GROUP-01/BLOCO 2).
///
/// [justCreated] (UX-01): `true` só quando `CreateGroupPage` chega até
/// aqui via `pushReplacement(..., extra: true)` - mesmo mecanismo de
/// `extra` já usado por `EditGroupPage`/`SubmitEventReviewPage` no
/// próprio `app_router.dart`, não um padrão novo. Dispara o diálogo de
/// "Grupo criado com sucesso" uma única vez: a checagem mora em
/// `initState`, que o Flutter garante executar exatamente uma vez por
/// instância de `State` - nenhum rebuild (setState, `ref.watch`,
/// provider reconstruindo) executa `initState` de novo, então não é
/// preciso nenhuma flag extra para "não mostrar de novo".
class GroupDetailPage extends ConsumerStatefulWidget {
  const GroupDetailPage({
    super.key,
    required this.groupId,
    this.justCreated = false,
  });

  final String groupId;
  final bool justCreated;

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupDetailControllerProvider.notifier).load(widget.groupId);
      if (widget.justCreated) _showCreatedDialog();
    });
  }

  Future<void> _showCreatedDialog() async {
    final shouldShare = await ConfirmationDialog.show(
      context,
      title: 'Grupo criado com sucesso',
      message: 'Convide seus amigos para começar os rolês.',
      confirmLabel: 'Compartilhar agora',
      cancelLabel: 'Agora não',
    );
    if (!mounted || !shouldShare) return;
    _shareInviteCode();
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

  Future<void> _editGroup(Group group) async {
    // Passa o `Group` já carregado via `extra` (mesmo mecanismo de
    // `NotificationDetailPage`, ver app_router.dart) - evita um `getById`
    // redundante só para preencher um formulário com dados que esta
    // tela já tem em memória.
    await context.push('/groups/${widget.groupId}/edit', extra: group);
    // Mesmo padrão de `GroupsListPage._createGroup` - edit_group_page.dart
    // só fecha (`context.pop()`); recarrega para refletir nome/descrição
    // possivelmente alterados.
    if (!mounted) return;
    ref.read(groupDetailControllerProvider.notifier).load(widget.groupId);
  }

  Future<void> _leaveGroup(GroupMember own) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sair do grupo',
      message: 'Você vai deixar de ver os rolês deste grupo. Deseja continuar?',
      confirmLabel: 'Sair',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(groupDetailControllerProvider.notifier).leaveGroup(own.id);
      if (!mounted) return;
      // RC-02D: mesmo padrão de bug já corrigido em Restaurantes/Rolês -
      // `GroupsListPage` só recarrega no próprio `initState`, então sem
      // isto o grupo continua aparecendo na lista (com dados obsoletos)
      // até o app ser reiniciado, mesmo já tendo saído com sucesso no
      // servidor.
      ref.read(groupsListControllerProvider.notifier).load();
      context.pop();
    } on GroupRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível sair do grupo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(groupDetailControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    ref.listen<GroupDetailStatus>(groupDetailControllerProvider, (
      previous,
      next,
    ) {
      // Só mostra snackbar quando já havia um grupo carregado (falha de
      // promover/remover) - a falha do `load()` inicial já vira tela de
      // erro no switch abaixo.
      if (next is GroupDetailError && next.details != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final detailsForActions = switch (status) {
      GroupDetailLoaded(:final details) => details,
      GroupDetailError(:final details) => details,
      _ => null,
    };
    final own = detailsForActions?.ownRole(currentUserId);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Grupo',
        // BLOCO 7: "Rolês" é a ação mais frequente, continua direta; as
        // demais (editar/ranking/estatísticas/sair) foram para um menu
        // (mesmo padrão de `PopupMenuButton` já usado nas linhas de
        // membro, BLOCO 2) - débito de UX registrado no relatório do
        // BLOCO 5 ("topbar sobrecarregada" com 4 ícones condicionais),
        // resolvido proativamente aqui em vez de esperar o BLOCO 9.
        actions: [
          AppIconButton(
            icon: Icons.event_outlined,
            tooltip: 'Rolês',
            onPressed: () => context.push('/groups/${widget.groupId}/events'),
          ),
          if (own != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editGroup(detailsForActions!.group);
                if (value == 'ranking') {
                  context.push('/groups/${widget.groupId}/ranking');
                }
                if (value == 'stats') {
                  context.push('/groups/${widget.groupId}/stats');
                }
                if (value == 'leave') _leaveGroup(own);
              },
              itemBuilder: (context) => [
                if (own.isAdminOrOwner)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar grupo'),
                  ),
                const PopupMenuItem(
                  value: 'ranking',
                  child: Text('Ranking do grupo'),
                ),
                const PopupMenuItem(
                  value: 'stats',
                  child: Text('Estatísticas'),
                ),
                // Owner não pode sair sem transferir a propriedade antes
                // (RLS `group_members_delete_self_or_admin`, GROUP-01) -
                // transferência de propriedade fica fora do escopo,
                // então a opção nem aparece para o owner.
                if (!own.isOwner)
                  const PopupMenuItem(
                    value: 'leave',
                    child: Text('Sair do grupo'),
                  ),
              ],
            ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          GroupDetailInitial() ||
          GroupDetailLoading() => const LoadingScreen(key: ValueKey('loading')),
          GroupDetailError(:final message, details: null) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref
                .read(groupDetailControllerProvider.notifier)
                .load(widget.groupId),
          ),
          GroupDetailLoaded(:final details) => _GroupDetailContent(
            key: const ValueKey('loaded'),
            details: details,
            currentUserId: currentUserId,
            onShare: _shareInviteCode,
          ),
          // Mesma `key` de `GroupDetailLoaded` de propósito (mesma
          // decisão do EventDetailPage, ROLÊ-03): uma falha ao promover/
          // remover não deve re-animar a tela inteira.
          GroupDetailError(:final details) => _GroupDetailContent(
            key: const ValueKey('loaded'),
            details: details!,
            currentUserId: currentUserId,
            onShare: _shareInviteCode,
          ),
        },
      ),
    );
  }
}

class _GroupDetailContent extends ConsumerWidget {
  const _GroupDetailContent({
    super.key,
    required this.details,
    required this.currentUserId,
    required this.onShare,
  });

  final GroupDetails details;
  final String? currentUserId;
  final VoidCallback onShare;

  Future<void> _promote(WidgetRef ref, GroupMember member) {
    return ref
        .read(groupDetailControllerProvider.notifier)
        .promoteToAdmin(member.id);
  }

  Future<void> _demote(WidgetRef ref, GroupMember member) {
    return ref
        .read(groupDetailControllerProvider.notifier)
        .demoteToMember(member.id);
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Remover membro',
      message:
          '${member.fullName ?? 'Este membro'} vai deixar de ver os rolês deste grupo. Deseja continuar?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!confirmed) return;
    await ref
        .read(groupDetailControllerProvider.notifier)
        .removeMember(member.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final group = details.group;
    final members = details.members;
    final own = details.ownRole(currentUserId);

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
          ...members.indexed.map((entry) {
            final member = entry.$2;
            final isSelf = member.userId == currentUserId;
            // Ninguém edita a linha do owner por aqui, e ninguém edita a
            // própria linha por este menu (sair é a ação dedicada no
            // topbar) - só sobra "outro membro, não-owner".
            final canManage = !isSelf && !member.isOwner && own != null;
            final canChangeRole = canManage && own.isOwner;
            final canRemove = canManage && own.isAdminOrOwner;

            return AppStaggeredListItem(
              index: entry.$1,
              child: ListTile(
                leading: ProfileAvatar(
                  avatarPath: member.avatarUrl,
                  radius: 20,
                ),
                title: Text(member.fullName ?? ''),
                trailing: !canChangeRole && !canRemove
                    ? AppBadge(label: member.roleLabel)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppBadge(label: member.roleLabel),
                          PopupMenuButton<String>(
                            // Mesmo padrão de `comments_page.dart`
                            // (`if`, não `switch` - evita a obrigação de
                            // `break` explícito em cada case).
                            onSelected: (value) {
                              if (value == 'promote') _promote(ref, member);
                              if (value == 'demote') _demote(ref, member);
                              if (value == 'remove') {
                                _remove(context, ref, member);
                              }
                            },
                            itemBuilder: (context) => [
                              if (canChangeRole && member.role == 'member')
                                const PopupMenuItem(
                                  value: 'promote',
                                  child: Text('Promover a administrador'),
                                ),
                              if (canChangeRole && member.role == 'admin')
                                const PopupMenuItem(
                                  value: 'demote',
                                  child: Text('Rebaixar a membro'),
                                ),
                              if (canRemove)
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remover do grupo'),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
