import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/follow_list_controller.dart';
import '../states/follow_list_status.dart';

/// Tela de Seguidores/Seguindo (DV-07 §6) - mesma tela para os dois
/// casos, parametrizada por [type].
class FollowListPage extends ConsumerStatefulWidget {
  const FollowListPage({super.key, required this.userId, required this.type});

  final String userId;
  final FollowListType type;

  @override
  ConsumerState<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends ConsumerState<FollowListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(followListControllerProvider.notifier)
          .load(widget.userId, widget.type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(followListControllerProvider);
    final title = widget.type == FollowListType.followers
        ? 'Seguidores'
        : 'Seguindo';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (status) {
        FollowListInitial() ||
        FollowListLoading() => const Center(child: CircularProgressIndicator()),
        FollowListError(:final message) => Center(child: Text(message)),
        FollowListEmpty() => Center(
          child: Text(
            widget.type == FollowListType.followers
                ? 'Nenhum seguidor ainda.'
                : 'Ainda não segue ninguém.',
          ),
        ),
        FollowListLoaded(:final result) => ListView.builder(
          itemCount: result.items.length,
          itemBuilder: (context, index) {
            final profile = result.items[index];
            return ListTile(
              title: Text(profile.fullName ?? ''),
              subtitle: profile.bio != null && profile.bio!.isNotEmpty
                  ? Text(profile.bio!)
                  : null,
              onTap: () => context.push('/users/${profile.id}'),
            );
          },
        ),
      },
    );
  }
}
