import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reviews/data/review_repository_impl.dart';

/// Estado local do botão de curtir de um `SocialFeedCard` (FASE SOCIAL 4).
class FeedLikeState {
  const FeedLikeState({required this.isLiked, required this.likesCount});

  final bool isLiked;
  final int likesCount;
}

/// Chave do `family` - inclui os valores iniciais (vindos do
/// `FeedReviewItem` já carregado) porque o provider nasce a partir deles;
/// mudar [reviewId] (novo card) recria o controller do zero.
class FeedLikeArgs {
  const FeedLikeArgs({
    required this.reviewId,
    required this.initialIsLiked,
    required this.initialLikesCount,
  });

  final String reviewId;
  final bool initialIsLiked;
  final int initialLikesCount;

  @override
  bool operator ==(Object other) =>
      other is FeedLikeArgs &&
      other.reviewId == reviewId &&
      other.initialIsLiked == initialIsLiked &&
      other.initialLikesCount == initialLikesCount;

  @override
  int get hashCode => Object.hash(reviewId, initialIsLiked, initialLikesCount);
}

/// Curtir/descurtir isolado por card (FASE SOCIAL 4, requisito de
/// performance: tocar em curtir nunca deve recarregar/reconstruir o Feed
/// inteiro). Reaproveita `ReviewRepository.like()`/`unlike()` já
/// existentes - nenhum backend novo. Atualização otimista: o estado muda
/// antes da resposta do servidor e é revertido só em caso de falha.
class FeedLikeController
    extends AutoDisposeFamilyNotifier<FeedLikeState, FeedLikeArgs> {
  @override
  FeedLikeState build(FeedLikeArgs arg) {
    return FeedLikeState(
      isLiked: arg.initialIsLiked,
      likesCount: arg.initialLikesCount,
    );
  }

  Future<void> toggle(String userId) async {
    final wasLiked = state.isLiked;
    final previousCount = state.likesCount;
    state = FeedLikeState(
      isLiked: !wasLiked,
      likesCount: wasLiked ? previousCount - 1 : previousCount + 1,
    );

    final repository = ref.read(reviewRepositoryProvider);
    try {
      if (wasLiked) {
        await repository.unlike(arg.reviewId, userId);
      } else {
        await repository.like(arg.reviewId, userId);
      }
    } catch (_) {
      state = FeedLikeState(isLiked: wasLiked, likesCount: previousCount);
    }
  }
}

final feedLikeControllerProvider = NotifierProvider.autoDispose
    .family<FeedLikeController, FeedLikeState, FeedLikeArgs>(
      FeedLikeController.new,
    );
