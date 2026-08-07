import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/collection_utils.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/cards/ranking_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_tabs.dart';
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

/// Tela unificada "Meu Grupo" (F23, `RC03_DESIGN_GAP.md §1.3`) - Ranking
/// + Estatísticas + Memórias em `AppTabs`, entrega 1 da FASE B.
///
/// `GroupRankingPage`/`GroupStatsPage` **continuam existindo** por
/// enquanto - esta tela não as substitui ainda, só oferece o mesmo
/// conteúdo em um único destino. A remoção das 2 rotas antigas (e desta
/// duplicação de Ranking/Estatísticas, que desaparece junto) é a
/// Entrega 5 da FASE B, não esta. Diferente da aba Memórias (ver
/// [_MemoriesTab]), a duplicação de Ranking/Estatísticas não tem um
/// componente compartilhado planejado - ela só some quando as telas
/// antigas forem deletadas, não por extração.
///
/// Sem rota própria ainda (mesmo padrão já usado para `AppTabs`/
/// `EventCard` na Sprint 1/FASE B0: infraestrutura construída e coberta
/// por teste de widget antes de ganhar um consumidor de navegação) - a
/// Entrega 5 é quem conecta esta tela a uma rota real.
class GroupHubPage extends ConsumerStatefulWidget {
  const GroupHubPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupHubPage> createState() => _GroupHubPageState();
}

class _GroupHubPageState extends ConsumerState<GroupHubPage> {
  @override
  void initState() {
    super.initState();
    // Carrega os 2 controllers de uma vez, não sob demanda por aba -
    // evita o flicker de "trocar de aba e ver Loading" para dado que já
    // poderia estar pronto (mesmo motivo de `GroupStatsPage` já carregar
    // ambos hoje).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupRankingControllerProvider.notifier).load(widget.groupId);
      ref.read(eventsListControllerProvider.notifier).load(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Meu grupo'),
      body: AppTabs(
        tabs: [
          AppTabItem(
            label: 'Ranking',
            child: _RankingTab(groupId: widget.groupId),
          ),
          AppTabItem(
            label: 'Estatísticas',
            child: _StatsTab(groupId: widget.groupId),
          ),
          AppTabItem(
            label: 'Memórias',
            child: _MemoriesTab(groupId: widget.groupId),
          ),
        ],
      ),
    );
  }
}

/// Mesmo conteúdo de `GroupRankingPage` (duplicado, não extraído - ver
/// doc de [GroupHubPage]).
class _RankingTab extends ConsumerWidget {
  const _RankingTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(groupRankingControllerProvider);

    return AppAnimatedSwitcher(
      child: switch (status) {
        GroupRankingInitial() || GroupRankingLoading() => const LoadingScreen(
          key: ValueKey('hub-ranking-loading'),
        ),
        GroupRankingError(:final message) => ErrorState(
          key: const ValueKey('hub-ranking-error'),
          message: message,
          onRetry: () =>
              ref.read(groupRankingControllerProvider.notifier).load(groupId),
        ),
        GroupRankingEmpty() => const EmptyState(
          key: ValueKey('hub-ranking-empty'),
          message: 'Este grupo ainda não tem rolês avaliados.',
        ),
        GroupRankingLoaded(:final entries) => ListView.builder(
          key: const ValueKey('hub-ranking-loaded'),
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final reviewsLabel = entry.reviewsCount == 1
                ? '1 avaliação'
                : '${entry.reviewsCount} avaliações';
            final eventsLabel = entry.eventsCount == 1
                ? '1 rolê'
                : '${entry.eventsCount} rolês';
            return AppStaggeredListItem(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: RankingCard(
                  position: index + 1,
                  name: entry.fullName ?? '',
                  subtitle: '$eventsLabel · $reviewsLabel',
                  trailingLabel: entry.averageScore?.toStringAsFixed(1),
                ),
              ),
            );
          },
        ),
      },
    );
  }
}

/// Mesmo conteúdo de `GroupStatsPage` (duplicado, não extraído - ver
/// doc de [GroupHubPage]).
class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    if (errorMessage != null) {
      return ErrorState(
        key: const ValueKey('hub-stats-error'),
        message: errorMessage,
        onRetry: () {
          ref.read(eventsListControllerProvider.notifier).load(groupId);
          ref.read(groupRankingControllerProvider.notifier).load(groupId);
        },
      );
    }
    if (events == null || entries == null) {
      return const LoadingScreen(key: ValueKey('hub-stats-loading'));
    }
    return _StatsContent(
      key: const ValueKey('hub-stats-loaded'),
      events: events,
      entries: entries,
      currentUserId: currentUserId,
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    super.key,
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
    final realized = events
        .where((e) => e.status != 'cancelled' && !e.isUpcoming)
        .toList();
    final own = _findOwn(entries, currentUserId);

    final distinctRestaurants = <String>{
      for (final e in realized) e.restaurantId,
    }.length;

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

    final visitsByRestaurant =
        <
          String,
          ({String name, int count, double ratingSum, int ratingCount})
        >{};
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
                  commonHour == null
                      ? '—'
                      : '${commonHour.toString().padLeft(2, '0')}h',
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
                  own?.averageScore == null
                      ? '—'
                      : own!.averageScore!.toStringAsFixed(1),
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

/// Mesmo conteúdo de `_EventsList._memoryCards()` em
/// `events_list_page.dart` - mas aqui a duplicação **é** o ponto
/// central desta entrega, não um detalhe incidental. Ver o comentário
/// completo em [_buildMemoryCards].
class _MemoriesTab extends ConsumerWidget {
  const _MemoriesTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(eventsListControllerProvider);

    return AppAnimatedSwitcher(
      child: switch (status) {
        EventsListInitial() || EventsListLoading() => const LoadingScreen(
          key: ValueKey('hub-memories-loading'),
        ),
        EventsListError(:final message) => ErrorState(
          key: const ValueKey('hub-memories-error'),
          message: message,
          onRetry: () =>
              ref.read(eventsListControllerProvider.notifier).load(groupId),
        ),
        EventsListEmpty() => const EmptyState(
          key: ValueKey('hub-memories-empty'),
          message: 'Este grupo ainda não tem rolês realizados.',
        ),
        EventsListLoaded(:final events) => _MemoriesContent(
          key: const ValueKey('hub-memories-loaded'),
          events: events,
        ),
      },
    );
  }
}

class _MemoriesContent extends StatelessWidget {
  const _MemoriesContent({super.key, required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    // Mesmo filtro de "realizados" de `_EventsList` (BLOCO 6): só rolês
    // passados (`!isUpcoming`) e não cancelados contam como memória.
    final realized = events
        .where((e) => !e.isUpcoming && e.status != 'cancelled')
        .toList();
    final cards = _buildMemoryCards(context, realized);

    if (cards.isEmpty) {
      return const EmptyState(
        message: 'Este grupo ainda não tem rolês realizados.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards,
      ),
    );
  }

  /// ## Duplicação deliberada e temporária (Entrega 1 da FASE B)
  ///
  /// Esta função é uma cópia intencional de
  /// `_EventsList._memoryCards()` (`events_list_page.dart`) - **não**
  /// uma tentativa de reaproveitamento malfeita, nem um esquecimento a
  /// ser corrigido depois "se sobrar tempo". Regra combinada
  /// explicitamente para a FASE B: **extrair um componente
  /// compartilhado só quando existirem 2 consumidores reais, nunca
  /// antes**. Antes desta tela existir, `EventsListPage` era o único
  /// consumidor - extrair um componente ali teria sido adivinhar a
  /// forma de uma reutilização que ainda não existia. A partir desta
  /// entrega, os 2 consumidores reais existem (`EventsListPage` e
  /// `GroupHubPage`) - a **Entrega 2** da FASE B extrai esta lógica
  /// (cálculo + renderização) para um componente único que os dois
  /// passam a chamar, eliminando esta cópia.
  ///
  /// ### Contrato do futuro componente compartilhado de Memórias
  ///
  /// Responsabilidades - o que ele **vai** fazer:
  /// - Recebe a lista de rolês já filtrada como "realizados" (mesmo
  ///   filtro usado aqui e em `_EventsList`) - quem chama filtra, o
  ///   componente nunca decide sozinho o que conta como realizado.
  /// - Agrega e renderiza as métricas de memória a partir dessa lista -
  ///   hoje: "mais visitado" e "campeão" (por nota média, agregada por
  ///   restaurante, nunca por rolê individual); a Entrega 3 da FASE B
  ///   adiciona "quem mais escolheu" ao mesmo componente, no mesmo lugar.
  /// - É reutilizável por qualquer tela futura que já tenha a lista de
  ///   rolês do grupo carregada - não é específica a `EventsListPage`/
  ///   `GroupHubPage` por construção, só por serem os 2 consumidores
  ///   que existem até agora.
  ///
  /// O que ele **nunca** deve fazer, sob nenhuma justificativa futura:
  /// - Nunca buscar dado sozinho - sem `ref.watch`/`ref.read` de
  ///   nenhum provider, sem repositório, sem controller próprio.
  ///   Recebe `List<Event>` já carregada por parâmetro, mesma regra já
  ///   aplicada a `RankingCard`/`EventCard` (componentes "burros").
  /// - Nunca decidir navegação (`context.push`/`context.go` dentro
  ///   dele) - qualquer interação (se um dia existir) delega via
  ///   callback (`onTap`), nunca decide sozinho para onde ir.
  /// - Nunca conhecer "grupo" ou "usuário atual" diretamente - recebe
  ///   só a lista já filtrada e, se algum card futuro precisar, um
  ///   dado já resolvido (ex.: `currentUserId`) como parâmetro simples,
  ///   nunca lendo um provider global por conta própria.
  /// - Nunca crescer por antecipação - um parâmetro/métrica nova só
  ///   entra quando essa métrica for de fato implementada numa entrega
  ///   real (nunca "para o caso de precisar depois").
  List<Widget> _buildMemoryCards(BuildContext context, List<Event> realized) {
    if (realized.isEmpty) return const [];

    final visitCounts = <String, int>{};
    final nameByRestaurant = <String, String>{};
    for (final event in realized) {
      visitCounts.update(event.restaurantId, (v) => v + 1, ifAbsent: () => 1);
      nameByRestaurant[event.restaurantId] = event.restaurantName ?? '';
    }
    final mostVisitedId = visitCounts.entries
        .reduce((a, b) => b.value > a.value ? b : a)
        .key;
    final mostVisitedCount = visitCounts[mostVisitedId]!;

    // Mesmo cuidado de `_EventsList`/`group_stats_page.dart` (QA-13):
    // agrega por restaurante antes de eleger o campeão - nunca pega
    // `averageRating` de um único rolê escolhido arbitrariamente.
    final ratingByRestaurant =
        <String, ({String name, double ratingSum, int ratingCount})>{};
    for (final event in realized) {
      final rating = event.averageRating;
      if (rating == null) continue;
      final current = ratingByRestaurant[event.restaurantId];
      ratingByRestaurant[event.restaurantId] = (
        name: event.restaurantName ?? '',
        ratingSum: (current?.ratingSum ?? 0) + rating,
        ratingCount: (current?.ratingCount ?? 0) + 1,
      );
    }
    String? championName;
    double? championAverage;
    for (final entry in ratingByRestaurant.values) {
      final average = entry.ratingSum / entry.ratingCount;
      if (championAverage == null || average > championAverage) {
        championName = entry.name;
        championAverage = average;
      }
    }

    return [
      Row(
        children: [
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mais visitado',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    nameByRestaurant[mostVisitedId] ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    mostVisitedCount == 1
                        ? '1 rolê'
                        : '$mostVisitedCount rolês',
                  ),
                ],
              ),
            ),
          ),
          if (championName != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campeão',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      championName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${championAverage!.toStringAsFixed(1)} ⭐'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ];
  }
}
