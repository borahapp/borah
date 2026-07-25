import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../application/reviews_controller.dart';
import '../states/reviews_status.dart';
import '../widgets/review_summary_tile.dart';

/// Tela de Lista de avaliações de um restaurante (DV-04).
class ReviewsListPage extends ConsumerStatefulWidget {
  const ReviewsListPage({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<ReviewsListPage> createState() => _ReviewsListPageState();
}

class _ReviewsListPageState extends ConsumerState<ReviewsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reviewsControllerProvider.notifier)
          .loadForRestaurant(widget.restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(reviewsControllerProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Avaliações',
        actions: [
          AppIconButton(
            icon: Icons.add,
            tooltip: 'Avaliar restaurante',
            onPressed: () =>
                context.push('/restaurants/${widget.restaurantId}/reviews/new'),
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          ReviewsInitial() ||
          ReviewsLoading() => const LoadingScreen(key: ValueKey('loading')),
          ReviewsError(:final message) => Center(
            key: const ValueKey('error'),
            child: Text(message),
          ),
          ReviewsEmpty() => const EmptyState(
            key: ValueKey('empty'),
            message: 'Nenhuma avaliação ainda.',
          ),
          ReviewsLoaded(:final result) => ListView.builder(
            key: const ValueKey('loaded'),
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final review = result.items[index];
              return AppStaggeredListItem(
                index: index,
                child: ReviewSummaryTile(
                  review: review,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16),
                      const SizedBox(width: 4),
                      Text('${review.likesCount}'),
                    ],
                  ),
                  onTap: () => context.push('/reviews/${review.id}'),
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
