import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/collection_utils.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../events/application/events_list_controller.dart';
import '../../../events/domain/event.dart';
import '../../../events/presentation/states/events_list_status.dart';
import '../../application/group_ranking_controller.dart';
import '../../domain/group_ranking_entry.dart';
import '../states/group_ranking_status.dart';

/// Tela de Estatísticas (BLOCO 7) - Grupo/Você/Restaurantes/Rolês, tudo
/// derivado de dados que dois controllers já existentes carregam
/// (`EventsListController`/`GroupRankingController`) - nenhum provider,
/// consulta ou tabela nova além da coluna `declined_count` (migration
/// `20260801120000_add_member_declined_count.sql`, extensão do trigger
/// do BLOCO 5).
class GroupStatsPage extends ConsumerStatefulWidget {
  const GroupStatsPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupStatsPage> createState() => _GroupStatsPageState();
}

class _GroupStatsPageState extends ConsumerState<GroupStatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsListControllerProvider.notifier).load(widget.groupId);
      ref.read(groupRankingControllerProvider.notifier).load(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsStatus = ref.watch(eventsListControllerProvider);
    final rankingStatus = ref.watch(groupRankingControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    final events = switch (eventsStatus) {
      EventsListLoaded(:final events) => events,
      EventsListEmpty() => const <Event>[],
      _ => null,
    };
    final entries = switch (rankingStatus) {
      GroupRankingLoaded(:final entries) => entries,
      GroupRankingEmpty() => const <GroupRankingEntry>[],
      _ => null,
    };

    final errorMessage = switch (eventsStatus) {
      EventsListError(:final message) => message,
      _ => switch (rankingStatus) {
        GroupRankingError(:final message) => message,
        _ => null,
      },
    };

    return Scaffold(
      appBar: const AppTopBar(title: 'Estatísticas'),
      body: errorMessage != null
          ? ErrorState(
              message: errorMessage,
              onRetry: () {
                ref.read(eventsListControllerProvider.notifier).load(widget.groupId);
                ref.read(groupRankingControllerProvider.notifier).load(widget.groupId);
              },
            )
          : (events == null || entries == null)
              ? const LoadingScreen()
              : _GroupStatsContent(
                  events: events,
                  entries: entries,
                  currentUserId: currentUserId,
                ),
    );
  }
}

class _GroupStatsContent extends StatelessWidget {
  const _GroupStatsContent({
    required this.events,
    required this.entries,
    required this.currentUserId,
  });

  final List<Event> events;
  final List<GroupRankingEntry> entries;
  final String? currentUserId;

  static const _weekdayNames = {
    1: 'Segunda-feira',
    2: 'Terça-feira',
    3: 'Quarta-feira',
    4: 'Quinta-feira',
    5: 'Sexta-feira',
    6: 'Sábado',
    7: 'Domingo',
  };

  @override
  Widget build(BuildContext context) {
    final realized = events.where((e) => e.status != 'cancelled' && !e.isUpcoming).toList();
    final own = _findOwn(entries, currentUserId);

    final distinctRestaurants = <String>{for (final e in realized) e.restaurantId}.length;

    final weekdayCounts = <int, int>{};
    final hourCounts = <int, int>{};
    for (final event in realized) {
      final weekday = event.scheduledAt.weekday;
      final hour = event.scheduledAt.hour;
      weekdayCounts.update(weekday, (v) => v + 1, ifAbsent: () => 1);
      hourCounts.update(hour, (v) => v + 1, ifAbsent: () => 1);
    }
    final commonWeekday = _mostCommonKey(weekdayCounts);
    final commonHour = _mostCommonKey(hourCounts);

    final byStatus = <String, int>{};
    for (final event in events) {
      byStatus.update(event.status, (v) => v + 1, ifAbsent: () => 1);
    }

    // Cada rolê tem sua PRÓPRIA `averageRating` (a avaliação coletiva é
    // por rolê, não por restaurante) - a nota do restaurante aqui é a
    // média entre as notas dos rolês já avaliados nele, não a nota de
    // um rolê qualquer escolhido arbitrariamente.
    final visitsByRestaurant =
        <String, ({String name, int count, double ratingSum, int ratingCount})>{};
    for (final event in realized) {
      final current = visitsByRestaurant[event.restaurantId];
      final rating = event.averageRating;
      visitsByRestaurant[event.restaurantId] = (
        name: event.restaurantName ?? '',
        count: (current?.count ?? 0) + 1,
        ratingSum: (current?.ratingSum ?? 0) + (rating ?? 0),
        ratingCount: (current?.ratingCount ?? 0) + (rating == null ? 0 : 1),
      );
    }
    final restaurantRows = visitsByRestaurant.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Grupo'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow('Total de rolês', '${events.length}'),
                _statRow('Restaurantes diferentes', '$distinctRestaurants'),
                _statRow(
                  'Dia mais comum',
                  commonWeekday == null ? '—' : _weekdayNames[commonWeekday]!,
                ),
                _statRow(
                  'Horário preferido',
                  commonHour == null ? '—' : '${commonHour.toString().padLeft(2, '0')}h',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Você'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow('Rolês confirmados', '${own?.eventsCount ?? 0}'),
                _statRow('Faltas', '${own?.declinedCount ?? 0}'),
                _statRow('Avaliações enviadas', '${own?.reviewsCount ?? 0}'),
                _statRow(
                  'Nota média dada',
                  own?.averageScore == null ? '—' : own!.averageScore!.toStringAsFixed(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Restaurantes'),
          const SizedBox(height: AppSpacing.sm),
          if (restaurantRows.isEmpty)
            const Text('Nenhum rolê realizado ainda.')
          else
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final row in restaurantRows)
                    _statRow(
                      row.name,
                      row.ratingCount == 0
                          ? '${row.count}x'
                          : '${row.count}x · '
                                '${(row.ratingSum / row.ratingCount).toStringAsFixed(1)} ⭐',
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Rolês'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow('Agendados', '${byStatus['scheduled'] ?? 0}'),
                _statRow('Realizados', '${realized.length}'),
                _statRow('Cancelados', '${byStatus['cancelled'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  GroupRankingEntry? _findOwn(List<GroupRankingEntry> entries, String? userId) {
    if (userId == null) return null;
    return firstWhereOrNull(entries, (entry) => entry.userId == userId);
  }

  int? _mostCommonKey(Map<int, int> counts) {
    if (counts.isEmpty) return null;
    var bestKey = counts.keys.first;
    var bestCount = counts[bestKey]!;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        bestKey = entry.key;
        bestCount = entry.value;
      }
    }
    return bestKey;
  }
}
