import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/reviews_controller.dart';
import '../states/reviews_status.dart';

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
      appBar: AppBar(
        title: const Text('Avaliações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                context.push('/restaurants/${widget.restaurantId}/reviews/new'),
          ),
        ],
      ),
      body: switch (status) {
        ReviewsInitial() ||
        ReviewsLoading() => const Center(child: CircularProgressIndicator()),
        ReviewsError(:final message) => Center(child: Text(message)),
        ReviewsEmpty() => const Center(child: Text('Nenhuma avaliação ainda.')),
        ReviewsLoaded(:final result) => ListView.builder(
          itemCount: result.items.length,
          itemBuilder: (context, index) {
            final review = result.items[index];
            return ListTile(
              title: Text(review.rating.toStringAsFixed(1)),
              subtitle: review.comment != null && review.comment!.isNotEmpty
                  ? Text(review.comment!)
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 16),
                  const SizedBox(width: 4),
                  Text('${review.likesCount}'),
                ],
              ),
              onTap: () => context.push('/reviews/${review.id}'),
            );
          },
        ),
      },
    );
  }
}
