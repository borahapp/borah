import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/cards/event_card.dart';
import '../../../../design_system/components/cards/group_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../events/domain/event.dart';
import '../../../groups/domain/event_summary.dart';
import '../../../groups/domain/group.dart';
import '../../../notifications/application/unread_notifications_count_provider.dart';
import '../../application/home_controller.dart';
import '../states/home_status.dart';

/// Nova Home do BORAH (FASE 01 da simplificação de produto) — substitui
/// o Feed na posição inicial de `HomeShellPage` (índice 0). Responde às
/// 3 perguntas da auditoria: qual é meu próximo rolê, quais são meus
/// grupos, como crio um rolê/grupo novo — nesta ordem de prioridade
/// visual. O Feed continua existindo (código/banco intactos), só sai
/// desta posição.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).load();
    });
  }

  /// FASE 02: resolve o grupo ANTES de abrir `CreateEventPage`, que
  /// continua exigindo `groupId` obrigatório (decisão explícita - ver
  /// auditoria da fase) - a Home nunca constrói a página sem saber o
  /// grupo, mesmo princípio que `EventsListPage` já aplicava para quem
  /// entra criando um rolê de dentro de um grupo.
  ///
  /// - 0 grupos: `/groups` já mostra o empty state certo
  ///   ("Criar grupo"/"Entrar com código") - nenhuma tela nova.
  /// - 1 grupo: direto para `CreateEventPage`, sem nenhuma tela
  ///   intermediária.
  /// - 2+ grupos: bottom sheet leve (`_selectGroup`), reaproveitando
  ///   `GroupCard` e os `groups` já carregados pelo `HomeController` -
  ///   nenhuma consulta nova ao Supabase.
  Future<void> _createEvent(List<Group> groups) async {
    if (groups.isEmpty) {
      await context.push('/groups');
    } else if (groups.length == 1) {
      await context.push('/groups/${groups.first.id}/events/new');
    } else {
      final selected = await _selectGroup(groups);
      if (selected == null || !mounted) return;
      await context.push('/groups/${selected.id}/events/new');
    }
    if (!mounted) return;
    ref.read(homeControllerProvider.notifier).load();
  }

  /// Bottom sheet "Escolha o grupo" (FASE 02) - mesmo padrão estrutural
  /// de `home_shell_page.dart._openCreateSheet` (`SafeArea`/`Column`
  /// dentro de `showModalBottomSheet`), mas devolvendo o [Group]
  /// escolhido em vez de navegar por dentro do próprio builder - quem
  /// decide o que fazer com a escolha é sempre `_createEvent`, nunca o
  /// sheet. Tocar num grupo fecha o sheet e devolve o valor; tocar fora
  /// (dismiss) devolve `null`.
  Future<Group?> _selectGroup(List<Group> groups) {
    return showModalBottomSheet<Group>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Escolha o grupo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Em qual grupo você quer criar este rolê?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...groups.map(
              (group) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: GroupCard(
                  name: group.name,
                  memberCount: group.memberCount ?? 1,
                  photoUrl: group.photoUrl,
                  nextEventLabel: _nextEventLabel(group.nextEvent),
                  onTap: () => Navigator.of(sheetContext).pop(group),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    await context.push('/groups/new');
    if (!mounted) return;
    ref.read(homeControllerProvider.notifier).load();
  }

  /// FASE 05: o controller de `/notifications` já invalida
  /// `unreadNotificationsCountProvider` sozinho ao marcar como lida (o
  /// sino, nunca desmontado pelo `IndexedStack` da shell, atualiza antes
  /// mesmo do retorno) - esta invalidação aqui é só rede de segurança
  /// para o momento exato do retorno, mesmo padrão já usado por
  /// `_createGroup`/`_createEvent` acima.
  Future<void> _openNotifications() async {
    await context.push('/notifications');
    if (!mounted) return;
    ref.invalidate(unreadNotificationsCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'BORAH',
        actions: [_NotificationBellAction(onPressed: _openNotifications)],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          HomeInitial() ||
          HomeLoading() => const LoadingScreen(key: ValueKey('loading')),
          HomeError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref.read(homeControllerProvider.notifier).load(),
          ),
          HomeLoaded(:final groups, :final heroEvent, :final heroEventGroup) =>
            _HomeContent(
              key: const ValueKey('loaded'),
              groups: groups,
              heroEvent: heroEvent,
              heroEventGroup: heroEventGroup,
              onCreateEvent: () => _createEvent(groups),
              onCreateGroup: _createGroup,
            ),
        },
      ),
    );
  }
}

/// FASE 05 - sino de notificações no `AppTopBar` da Home. `ConsumerWidget`
/// próprio (não inline em `_HomePageState.build`) para que só o badge
/// recomponha quando `unreadNotificationsCountProvider` mudar, sem
/// reconstruir o resto da `AppTopBar`/Home.
class _NotificationBellAction extends ConsumerWidget {
  const _NotificationBellAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `.valueOrNull` (não `.when`): carregamento e erro de contagem
    // nunca escondem o sino nem bloqueiam o acesso a `/notifications` -
    // só o badge numérico fica ausente nesses dois casos, mesmo
    // comportamento visual de "sem notificações não lidas" (FASE 05,
    // critério de aceite 7).
    final count = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final compactCount = count > 99 ? '99+' : '$count';

    return Badge(
      label: Text(compactCount),
      isLabelVisible: count > 0,
      child: AppIconButton(
        icon: Icons.notifications_outlined,
        tooltip: count > 0
            ? 'Notificações, $count não lida${count == 1 ? '' : 's'}'
            : 'Notificações',
        onPressed: onPressed,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    super.key,
    required this.groups,
    required this.heroEvent,
    required this.heroEventGroup,
    required this.onCreateEvent,
    required this.onCreateGroup,
  });

  final List<Group> groups;
  final Event? heroEvent;
  final Group? heroEventGroup;
  final VoidCallback onCreateEvent;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    // `SingleChildScrollView` + `Column`, não `ListView`: a Home é uma
    // composição de seções heterogêneas (texto, botão, card-ou-vazio,
    // lista de grupos), não uma lista homogênea - `ListView` (sliver)
    // quebra o layout de filhos que usam `Center` internamente (caso de
    // `EmptyState`, achado real ao rodar os testes desta fase).
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qual vai ser o próximo rolê?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(label: 'Criar novo rolê', onPressed: onCreateEvent),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Próximo rolê'),
          const SizedBox(height: AppSpacing.sm),
          _NextEventSection(
            heroEvent: heroEvent,
            heroEventGroup: heroEventGroup,
            onCreateEvent: onCreateEvent,
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Meus grupos',
            action: AppTextButton(
              label: '+ Criar grupo',
              onPressed: onCreateGroup,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MyGroupsSection(groups: groups, onCreateGroup: onCreateGroup),
        ],
      ),
    );
  }
}

class _NextEventSection extends StatelessWidget {
  const _NextEventSection({
    required this.heroEvent,
    required this.heroEventGroup,
    required this.onCreateEvent,
  });

  final Event? heroEvent;
  final Group? heroEventGroup;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final event = heroEvent;
    final group = heroEventGroup;
    if (event == null || group == null) {
      return EmptyState(
        message: 'Você ainda não tem nenhum rolê marcado.',
        action: AppPrimaryButton(
          label: 'Criar meu primeiro rolê',
          onPressed: onCreateEvent,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Text(group.name, style: Theme.of(context).textTheme.bodySmall),
        ),
        EventCard(
          restaurantName: event.restaurantName ?? '',
          dateTimeLabel: _formatDateTime(event.scheduledAt),
          confirmedCount: event.confirmedCount,
          status: event.status,
          statusLabel: event.statusLabel,
          restaurantPhotoUrl: event.restaurantCoverImage,
          onTap: () => context.push('/groups/${group.id}/events/${event.id}'),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year} · $hour:$minute';
  }
}

class _MyGroupsSection extends StatelessWidget {
  const _MyGroupsSection({required this.groups, required this.onCreateGroup});

  final List<Group> groups;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return EmptyState(
        message: 'Você ainda não participa de nenhum grupo.',
        action: AppPrimaryButton(
          label: 'Criar grupo',
          onPressed: onCreateGroup,
        ),
      );
    }

    return Column(
      children: groups.indexed.map((entry) {
        final (index, group) = entry;
        return AppStaggeredListItem(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GroupCard(
              name: group.name,
              memberCount: group.memberCount ?? 1,
              photoUrl: group.photoUrl,
              nextEventLabel: _nextEventLabel(group.nextEvent),
              onTap: () => context.push('/groups/${group.id}'),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Mesma formatação de `groups_list_page.dart._nextEventLabel` —
/// formatação pertence à apresentação, não ao domínio. Função de nível
/// de arquivo (FASE 02): reaproveitada tanto por `_MyGroupsSection`
/// quanto pelo bottom sheet "Escolha o grupo" de `_HomePageState`.
String? _nextEventLabel(EventSummary? nextEvent) {
  if (nextEvent == null) return null;
  final date = nextEvent.scheduledAt;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return 'Próximo rolê: $day/$month';
}
