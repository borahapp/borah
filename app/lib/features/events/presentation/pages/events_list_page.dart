import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/events_list_controller.dart';
import '../../domain/event.dart';
import '../states/events_list_status.dart';

/// Tela "Rolês do grupo" (ROLÊ-03; separação Próximos/Realizados
/// adicionada no BLOCO 3 - resolve o débito registrado no relatório do
/// ROLÊ-03) — mesmo padrão de `groups_list_page.dart` (botão "+" no
/// `AppTopBar.actions` para criar, switch Loading/Error/Empty/Loaded
/// com `AppAnimatedSwitcher`).
class EventsListPage extends ConsumerStatefulWidget {
  const EventsListPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends ConsumerState<EventsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsListControllerProvider.notifier).load(widget.groupId);
    });
  }

  Future<void> _createEvent() async {
    await context.push('/groups/${widget.groupId}/events/new');
    // create_event_page.dart só fecha (`context.pop()`, sem valor de
    // retorno - ver ROLÊ-02) - a lista recarrega sozinha ao voltar,
    // mesmo padrão de `groups_list_page.dart._createGroup`.
    if (!mounted) return;
    ref.read(eventsListControllerProvider.notifier).load(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(eventsListControllerProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Rolês',
        actions: [
          AppIconButton(
            icon: Icons.add,
            tooltip: 'Criar rolê',
            onPressed: _createEvent,
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          EventsListInitial() ||
          EventsListLoading() => const LoadingScreen(key: ValueKey('loading')),
          EventsListError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref
                .read(eventsListControllerProvider.notifier)
                .load(widget.groupId),
          ),
          EventsListEmpty() => EmptyState(
            key: const ValueKey('empty'),
            message: 'Este grupo ainda não tem rolês.',
            action: AppPrimaryButton(
              label: 'Criar rolê',
              onPressed: _createEvent,
            ),
          ),
          EventsListLoaded(:final events) => _EventsList(
            key: const ValueKey('loaded'),
            groupId: widget.groupId,
            events: events,
          ),
        },
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({super.key, required this.groupId, required this.events});

  final String groupId;
  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    // BLOCO 3: `Event.isUpcoming` já resolve isso sem nenhuma consulta
    // nova - a lista continua vindo de uma única chamada a
    // `listByGroup`, só a apresentação separa os dois grupos.
    final upcoming = events.where((e) => e.isUpcoming).toList();
    final past = events.where((e) => !e.isUpcoming).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (upcoming.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SectionHeader(title: 'Próximos'),
          ),
          ...upcoming.indexed.map((entry) => _tile(context, entry.$1, entry.$2)),
        ],
        if (past.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SectionHeader(title: 'Realizados'),
          ),
          ...past.indexed.map((entry) => _tile(context, entry.$1, entry.$2)),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, int index, Event event) {
    return AppStaggeredListItem(
      index: index,
      child: ListTile(
        title: Text(event.restaurantName ?? ''),
        subtitle: Text(_formatDateTime(event.scheduledAt)),
        trailing: event.status == 'cancelled'
            ? AppBadge(label: event.statusLabel, earned: false)
            : null,
        onTap: () => context.push('/groups/$groupId/events/${event.id}'),
      ),
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
