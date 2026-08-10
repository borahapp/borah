import '../../../../core/models/paged_result.dart';
import '../../domain/feed_item.dart';

/// Estado do Feed (FASE SOCIAL 4), sealed class - compartilhado pelos 2
/// controllers (Para Você/Seguindo), cada um com sua própria instância.
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

  final PagedResult<FeedItem> result;
}

/// Atualização em segundo plano de um feed já carregado (DV-07 §10
/// "Refreshing"), mantendo o resultado anterior visível - mesmo padrão do
/// `FavoritesSyncing` do DV-06.
final class FeedRefreshing extends FeedStatus {
  const FeedRefreshing(this.result);

  final PagedResult<FeedItem> result;
}

final class FeedEmpty extends FeedStatus {
  const FeedEmpty();
}

final class FeedError extends FeedStatus {
  const FeedError(this.message);

  final String message;
}
