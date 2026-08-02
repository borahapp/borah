import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/groups_list_controller.dart';
import '../../domain/group.dart';
import '../states/groups_list_status.dart';

/// Tela "Meus Grupos" (GROUP-02B.0; ação de entrar por código
/// adicionada no ONBOARDING-01) — mesmo padrão de
/// `restaurants_search_page.dart` (botões no `AppTopBar.actions` para
/// criar) e `favorites_page.dart` (switch Loading/Error/Empty/Loaded
/// com `AppAnimatedSwitcher`). Sem membros/ranking/estatísticas/edição
/// — fora do escopo desta sprint.
class GroupsListPage extends ConsumerStatefulWidget {
  const GroupsListPage({super.key});

  @override
  ConsumerState<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends ConsumerState<GroupsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsListControllerProvider.notifier).load();
    });
  }

  Future<void> _createGroup() async {
    await context.push('/groups/new');
    // UX-01: desde esta rodada, `create_group_page.dart` não fecha mais
    // de volta para esta lista em caso de sucesso - vai direto para
    // `GroupDetailPage` via `pushReplacement` (ver CreateGroupPage). Este
    // `await` só resolve, então, se o usuário voltar sem criar nada
    // (botão de voltar do sistema) ou depois de já ter navegado adiante
    // e eventualmente retornar até aqui - o reload abaixo continua
    // correto nos dois casos (idempotente, sem custo perceptível).
    if (!mounted) return;
    ref.read(groupsListControllerProvider.notifier).load();
  }

  Future<void> _joinGroup() async {
    await context.push('/groups/join');
    // Mesmo padrão de `_createGroup` - join_group_page.dart também só
    // fecha (`context.pop()`, sem valor de retorno).
    if (!mounted) return;
    ref.read(groupsListControllerProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(groupsListControllerProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Grupos',
        actions: [
          // "Entrar" antes de "Criar": para a maioria dos usuários, um
          // grupo já existe (criado por um amigo) - entrar por código é
          // a ação mais comum, não criar um grupo novo (ONBOARDING-01).
          AppIconButton(
            icon: Icons.group_add_outlined,
            tooltip: 'Entrar com código',
            onPressed: _joinGroup,
          ),
          AppIconButton(
            icon: Icons.add,
            tooltip: 'Criar grupo',
            onPressed: _createGroup,
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          GroupsListInitial() ||
          GroupsListLoading() => const LoadingScreen(key: ValueKey('loading')),
          GroupsListError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () =>
                ref.read(groupsListControllerProvider.notifier).load(),
          ),
          GroupsListEmpty() => EmptyState(
            key: const ValueKey('empty'),
            message: 'Você ainda não participa de nenhum grupo.',
            action: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppPrimaryButton(
                  label: 'Entrar com código',
                  onPressed: _joinGroup,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppOutlinedButton(
                  label: 'Criar grupo',
                  onPressed: _createGroup,
                ),
              ],
            ),
          ),
          GroupsListLoaded(:final groups) => _GroupsList(
            key: const ValueKey('loaded'),
            groups: groups,
          ),
        },
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  const _GroupsList({super.key, required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return AppStaggeredListItem(
          index: index,
          child: ListTile(
            title: Text(group.name),
            subtitle: group.description != null
                ? Text(group.description!)
                : null,
            onTap: () => context.push('/groups/${group.id}'),
          ),
        );
      },
    );
  }
}
