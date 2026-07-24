import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/feedback/empty_state.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      ref.read(feedControllerProvider.notifier).loadForUser(userId);
    });
  }

  Future<void> _refresh() {
    return ref.read(feedControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Feed'),
      body: switch (status) {
        FeedInitial() || FeedLoading() => const LoadingScreen(),
        FeedError(:final message) => Center(child: Text(message)),
        FeedEmpty() => const EmptyState(
          message: 'Nenhuma avaliação de quem você segue ainda.',
        ),
        FeedRefreshing(:final result) ||
        FeedLoaded(:final result) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final review = result.items[index];
              return ReviewSummaryTile(
                review: review,
                onTap: () => context.push('/reviews/${review.id}'),
              );
            },
          ),
        ),
      },
    );
  }
}
