import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../users/domain/user_profile.dart';
import '../../application/follow_list_controller.dart';
import '../../data/follower_repository_impl.dart';
import '../states/follow_list_status.dart';
import '../widgets/person_list_tile.dart';

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
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // FASE SOCIAL 2 - status de Seguir/Seguindo de cada linha, buscado em
  // 1 consulta em lote (`listFollowingAmong`) sempre que a quantidade de
  // itens carregados muda, não 1 consulta por linha (N+1).
  Set<String> _followingIds = {};
  int _followingStatusForCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(followListControllerProvider.notifier)
          .load(widget.userId, widget.type);
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _syncFollowingStatus(List<UserProfile> items) async {
    if (items.length == _followingStatusForCount) return;
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final ids = items.map((p) => p.id).toList();
    final targetCount = items.length;
    try {
      final result = await ref
          .read(followerRepositoryProvider)
          .listFollowingAmong(currentUserId, ids);
      if (!mounted) return;
      setState(() {
        _followingIds = result;
        _followingStatusForCount = targetCount;
      });
    } catch (_) {
      // Falha silenciosa: os botões ficam como "Seguir" até a próxima
      // tentativa - não é grave o suficiente para bloquear a lista
      // inteira com uma tela de erro.
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _isLoadingMore = true;
    ref.read(followListControllerProvider.notifier).loadNextPage().whenComplete(
      () {
        if (mounted) _isLoadingMore = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(followListControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final title = widget.type == FollowListType.followers
        ? 'Seguidores'
        : 'Seguindo';

    ref.listen<FollowListStatus>(followListControllerProvider, (
      previous,
      next,
    ) {
      if (next is FollowListLoaded) {
        _syncFollowingStatus(next.result.items);
      }
    });

    return Scaffold(
      appBar: AppTopBar(title: title),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          FollowListInitial() ||
          FollowListLoading() => const LoadingScreen(key: ValueKey('loading')),
          FollowListError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref
                .read(followListControllerProvider.notifier)
                .load(widget.userId, widget.type),
          ),
          FollowListEmpty() => EmptyState(
            key: const ValueKey('empty'),
            message: widget.type == FollowListType.followers
                ? 'Nenhum seguidor ainda.'
                : 'Ainda não segue ninguém.',
          ),
          FollowListLoaded(:final result) => ListView.builder(
            key: const ValueKey('loaded'),
            controller: _scrollController,
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final profile = result.items[index];
              return AppStaggeredListItem(
                index: index,
                child: PersonListTile(
                  person: profile,
                  currentUserId: currentUserId,
                  initialIsFollowing: _followingIds.contains(profile.id),
                  onTap: () => context.push('/users/${profile.id}'),
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
