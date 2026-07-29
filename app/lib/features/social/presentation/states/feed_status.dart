import '../../../../core/models/paged_result.dart';
import '../../../reviews/domain/review.dart';

/// Estado do Feed (DV-07 §10), sealed class.
sealed class FeedStatus {
  const FeedStatus();
}

final class FeedInitial extends FeedStatus {
  const FeedInitial();
}

final class FeedLoading extends FeedStatus {
  const FeedLoading();
}

final class FeedLoaded extends FeedStatus {
  const FeedLoaded(this.result);

  final PagedResult<Review> result;
}

/// Atualização em segundo plano de um feed já carregado (DV-07 §10
/// "Refreshing"), mantendo o resultado anterior visível - mesmo padrão do
/// `FavoritesSyncing` do DV-06.
final class FeedRefreshing extends FeedStatus {
  const FeedRefreshing(this.result);

  final PagedResult<Review> result;
}

final class FeedEmpty extends FeedStatus {
  const FeedEmpty();
}

final class FeedError extends FeedStatus {
  const FeedError(this.message);

  final String message;
}
