import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/cards/ranking_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../application/group_ranking_controller.dart';
import '../states/group_ranking_status.dart';

/// Tela de Ranking do Grupo (BLOCO 5) - reaproveita `RankingCard`
/// (design system) tal qual `RankingUsersPage`/`RankingsPage` já fazem:
/// as 3 primeiras posições já mostram a medalha oficial automaticamente
/// (🥇🥈🥉 do pedido original, resolvido pelo próprio componente, sem
/// UI nova). Ordenado por rolês participados (critério primário,
/// decisão registrada na migration `20260801110000_add_group_ranking_
/// columns.sql`); "histórico" por membro fica para o módulo de
/// Memórias (BLOCO 6), não duplicado aqui.
class GroupRankingPage extends ConsumerStatefulWidget {
  const GroupRankingPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupRankingPage> createState() => _GroupRankingPageState();
}

class _GroupRankingPageState extends ConsumerState<GroupRankingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupRankingControllerProvider.notifier).load(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(groupRankingControllerProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Ranking do grupo'),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          GroupRankingInitial() ||
          GroupRankingLoading() => const LoadingScreen(key: ValueKey('loading')),
          GroupRankingError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref
                .read(groupRankingControllerProvider.notifier)
                .load(widget.groupId),
          ),
          // Mesmo padrão de `RankingsPage` (ranking global): sem ação
          // própria de criar - o ranking é derivado dos rolês do grupo,
          // não de algo que se cria a partir desta tela.
          GroupRankingEmpty() => const EmptyState(
            key: ValueKey('empty'),
            message: 'Este grupo ainda não tem rolês avaliados.',
          ),
          GroupRankingLoaded(:final entries) => ListView.builder(
            key: const ValueKey('loaded'),
            padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.only(bottom: 12),
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
      ),
    );
  }
}
