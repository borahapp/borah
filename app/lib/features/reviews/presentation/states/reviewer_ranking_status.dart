import '../../../../core/models/paged_result.dart';
import '../../domain/reviewer_ranking_entry.dart';

/// Estado do Ranking de Avaliadores (rodada "perfil individual como
/// centro", pós-FASE 09, Item E), sealed class - mesmo formato de
/// `RankingUsersStatus` (DV-10).
sealed class ReviewerRankingStatus {
  const ReviewerRankingStatus();
}

final class ReviewerRankingInitial extends ReviewerRankingStatus {
  const ReviewerRankingInitial();
}

final class ReviewerRankingLoading extends ReviewerRankingStatus {
  const ReviewerRankingLoading();
}

final class ReviewerRankingLoaded extends ReviewerRankingStatus {
  const ReviewerRankingLoaded(this.result);

  final PagedResult<ReviewerRankingEntry> result;
}

final class ReviewerRankingEmpty extends ReviewerRankingStatus {
  const ReviewerRankingEmpty();
}

final class ReviewerRankingError extends ReviewerRankingStatus {
  const ReviewerRankingError(this.message);

  final String message;
}
