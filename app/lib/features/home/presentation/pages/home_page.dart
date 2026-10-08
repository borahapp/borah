import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  /// FASE 01: só o novo ponto de entrada — reaproveita exatamente o
  /// mesmo fluxo que o bottom sheet "Criar" já usa hoje
  /// (`home_shell_page.dart._openCreateSheet`, item "Criar rolê"). A
  /// melhoria de pular a escolha de grupo quando só há 1 fica para a
  /// FASE 02 (não misturar as duas fases).
  Future<void> _createEvent() async {
    await context.push('/groups');
    if (!mounted) return;
    ref.read(homeControllerProvider.notifier).load();
  }

  Future<void> _createGroup() async {
    await context.push('/groups/new');
    if (!mounted) return;
    ref.read(homeControllerProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'BORAH'),
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
              onCreateEvent: _createEvent,
              onCreateGroup: _createGroup,
            ),
        },
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
          AppPrimaryButton(
            label: 'Criar novo rolê',
            onPressed: onCreateEvent,
          ),
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

  /// Mesma formatação de `groups_list_page.dart._nextEventLabel` —
  /// formatação pertence à apresentação, não ao domínio.
  String? _nextEventLabel(EventSummary? nextEvent) {
    if (nextEvent == null) return null;
    final date = nextEvent.scheduledAt;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'Próximo rolê: $day/$month';
  }
}
