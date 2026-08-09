import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../reviews/presentation/widgets/review_summary_tile.dart';
import '../../application/feed_controller.dart';
import '../states/feed_status.dart';

/// Tela de Feed (DV-07 §5, escopo restrito): avaliações recentes de
/// usuários seguidos - sem favoritos ou conquistas de gamificação
/// (decisão do DV-07).
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
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
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref.read(feedControllerProvider.notifier).loadForUser(userId);
  }

  Future<void> _refresh() {
    return ref.read(feedControllerProvider.notifier).refresh();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _isLoadingMore = true;
    ref.read(feedControllerProvider.notifier).loadNextPage().whenComplete(() {
      if (mounted) _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Feed',
        actions: [
          AppIconButton(
            icon: Icons.search,
            tooltip: 'Pesquisar',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          FeedInitial() ||
          FeedLoading() => const LoadingScreen(key: ValueKey('loading')),
          FeedError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: _load,
          ),
          FeedEmpty() => const EmptyState(
            key: ValueKey('empty'),
            message: 'Nenhuma avaliação de quem você segue ainda.',
          ),
          FeedRefreshing(:final result) ||
          FeedLoaded(:final result) => RefreshIndicator(
            key: const ValueKey('loaded'),
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              // Sem isto, um `ScrollController` explícito desativa o
              // scroll "sempre disponível" que `RefreshIndicator`
              // precisa para funcionar em listas pequenas (que não
              // preenchem a viewport) - regressão real encontrada por
              // `feed_page_test.dart` ao conectar o scroll desta fase.
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: result.items.length,
              itemBuilder: (context, index) {
                final review = result.items[index];
                return AppStaggeredListItem(
                  index: index,
                  child: ReviewSummaryTile(
                    review: review,
                    onTap: () => context.push('/reviews/${review.id}'),
                  ),
                );
              },
            ),
          ),
        },
      ),
    );
  }
}
