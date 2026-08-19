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
import '../../application/review_detail_controller.dart';
import '../../application/reviews_controller.dart';
import '../../domain/review.dart';
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
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reviewsControllerProvider.notifier)
          .loadForRestaurant(widget.restaurantId);
    });
    _scrollController.addListener(_onScroll);
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
    ref.read(reviewsControllerProvider.notifier).loadNextPage().whenComplete(
      () {
        if (mounted) _isLoadingMore = false;
      },
    );
  }

  /// BETA-RELEASE-09: `reviews_user_restaurant_unique` permite no máximo
  /// uma avaliação por usuário por restaurante - localiza a review do
  /// usuário atual entre os itens JÁ carregados por esta lista (sem
  /// consulta extra) para decidir entre "Avaliar restaurante" e "Editar
  /// minha avaliação". Só enxerga páginas já buscadas: se a review do
  /// usuário estiver numa página posterior ainda não carregada, o botão
  /// "+" aparece normalmente até essa página ser alcançada.
  Review? _findMyReview(ReviewsStatus status, String? currentUserId) {
    if (currentUserId == null || status is! ReviewsLoaded) return null;
    for (final review in status.result.items) {
      if (review.userId == currentUserId) return review;
    }
    return null;
  }

  /// Reaproveita exatamente o par `load()` + rota `/edit` já usado por
  /// `ReviewDetailPage` (o `EditReviewPage` só pré-preenche o formulário
  /// quando o controller já está em `ReviewDetailLoaded`) - nenhuma lógica
  /// nova de carregamento/edição é criada aqui.
  Future<void> _editMyReview(Review myReview, String currentUserId) async {
    await ref
        .read(reviewDetailControllerProvider.notifier)
        .load(myReview.id, currentUserId: currentUserId);
    if (!mounted) return;
    context.push('/reviews/${myReview.id}/edit');
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(reviewsControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final myReview = _findMyReview(status, currentUserId);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Avaliações',
        actions: [
          if (myReview == null)
            AppIconButton(
              icon: Icons.add,
              tooltip: 'Avaliar restaurante',
              onPressed: () => context.push(
                '/restaurants/${widget.restaurantId}/reviews/new',
              ),
            )
          else
            AppIconButton(
              icon: Icons.edit,
              tooltip: 'Editar minha avaliação',
              onPressed: () => _editMyReview(myReview, currentUserId!),
            ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          ReviewsInitial() ||
          ReviewsLoading() => const LoadingScreen(key: ValueKey('loading')),
          ReviewsError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref
                .read(reviewsControllerProvider.notifier)
                .loadForRestaurant(widget.restaurantId),
          ),
          ReviewsEmpty() => const EmptyState(
            key: ValueKey('empty'),
            message: 'Nenhuma avaliação ainda.',
          ),
          ReviewsLoaded(:final result) => ListView.builder(
            key: const ValueKey('loaded'),
            controller: _scrollController,
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
