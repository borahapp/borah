import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/cards/ranking_card.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/ranking_users_controller.dart';
import '../states/ranking_users_status.dart';

/// Tela de Ranking de Usuários (DV-10 §5/§6): Global e Entre Amigos.
class RankingUsersPage extends ConsumerStatefulWidget {
  const RankingUsersPage({super.key});

  @override
  ConsumerState<RankingUsersPage> createState() => _RankingUsersPageState();
}

class _RankingUsersPageState extends ConsumerState<RankingUsersPage> {
  RankingUsersType _type = RankingUsersType.global;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref.read(rankingUsersControllerProvider.notifier).load(userId, _type);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(rankingUsersControllerProvider);

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
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() => _type = selection.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: switch (status) {
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
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final entry = result.items[index];
                  final position = (result.page - 1) * result.limit + index + 1;
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
