import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/cards/ranking_card.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../reviews/application/reviewer_ranking_controller.dart';
import '../../../reviews/presentation/states/reviewer_ranking_status.dart';
import '../../application/ranking_users_controller.dart';
import '../states/ranking_users_status.dart';

/// Tela de Ranking de Usuários (DV-10 §5/§6): Global e Entre Amigos (por
/// XP/pontos, via `RankingUsersController`) e, rodada "perfil individual
/// como centro" (pós-FASE 09, Item E), Avaliadores (por quantidade de
/// restaurantes avaliados, via `ReviewerRankingController` - métrica
/// diferente, por isso um controller/repositório diferente por trás do
/// mesmo `SegmentedButton`).
class RankingUsersPage extends ConsumerStatefulWidget {
  const RankingUsersPage({super.key});

  @override
  ConsumerState<RankingUsersPage> createState() => _RankingUsersPageState();
}

class _RankingUsersPageState extends ConsumerState<RankingUsersPage> {
  RankingUsersType _type = RankingUsersType.global;
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _load() {
    if (_type == RankingUsersType.reviewers) {
      ref.read(reviewerRankingControllerProvider.notifier).load();
      return;
    }
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref.read(rankingUsersControllerProvider.notifier).load(userId, _type);
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _isLoadingMore = true;
    final future = _type == RankingUsersType.reviewers
        ? ref.read(reviewerRankingControllerProvider.notifier).loadNextPage()
        : ref.read(rankingUsersControllerProvider.notifier).loadNextPage();
    future.whenComplete(() {
      if (mounted) _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(rankingUsersControllerProvider);
    final reviewerStatus = ref.watch(reviewerRankingControllerProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Ranking de Usuários'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<RankingUsersType>(
              segments: const [
                ButtonSegment(
                  value: RankingUsersType.global,
                  label: Text('Global'),
                ),
                ButtonSegment(
                  value: RankingUsersType.friends,
                  label: Text('Amigos'),
                ),
                ButtonSegment(
                  value: RankingUsersType.reviewers,
                  label: Text('Avaliadores'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() => _type = selection.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _type == RankingUsersType.reviewers
                ? switch (reviewerStatus) {
                    ReviewerRankingInitial() ||
                    ReviewerRankingLoading() => const LoadingScreen(),
                    ReviewerRankingError(:final message) => ErrorState(
                      message: message,
                      onRetry: _load,
                    ),
                    ReviewerRankingEmpty() => const EmptyState(
                      message: 'Nenhum resultado ainda.',
                    ),
                    ReviewerRankingLoaded(:final result) => ListView.builder(
                      controller: _scrollController,
                      itemCount: result.items.length,
                      itemBuilder: (context, index) {
                        final entry = result.items[index];
                        final position = index + 1;
                        return RankingCard(
                          position: position,
                          name: entry.fullName ?? '',
                          trailingLabel:
                              '${entry.reviewsCount} '
                              'avaliaç${entry.reviewsCount == 1 ? 'ão' : 'ões'}',
                        );
                      },
                    ),
                  }
                : switch (status) {
                    RankingUsersInitial() ||
                    RankingUsersLoading() => const LoadingScreen(),
                    RankingUsersError(:final message) => ErrorState(
                      message: message,
                      onRetry: _load,
                    ),
                    RankingUsersEmpty() => const EmptyState(
                      message: 'Nenhum resultado ainda.',
                    ),
                    RankingUsersLoaded(:final result) => ListView.builder(
                      controller: _scrollController,
                      itemCount: result.items.length,
                      itemBuilder: (context, index) {
                        final entry = result.items[index];
                        final position = index + 1;
                        return RankingCard(
                          position: position,
                          name: entry.fullName ?? '',
                          subtitle: 'Nível ${entry.progress.level}',
                          trailingLabel: '${entry.progress.points} pts',
                        );
                      },
                    ),
                  },
          ),
        ],
      ),
    );
  }
}
