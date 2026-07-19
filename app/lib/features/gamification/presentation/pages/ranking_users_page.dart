import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(title: const Text('Ranking de Usuários')),
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
              RankingUsersInitial() || RankingUsersLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              RankingUsersError(:final message) => Center(child: Text(message)),
              RankingUsersEmpty() => const Center(
                child: Text('Nenhum resultado ainda.'),
              ),
              RankingUsersLoaded(:final result) => ListView.builder(
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final entry = result.items[index];
                  final position = (result.page - 1) * result.limit + index + 1;
                  return ListTile(
                    leading: CircleAvatar(child: Text('$position')),
                    title: Text(entry.fullName ?? ''),
                    subtitle: Text('Nível ${entry.progress.level}'),
                    trailing: Text('${entry.progress.points} pts'),
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
