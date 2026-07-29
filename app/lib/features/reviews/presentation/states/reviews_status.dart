import '../../../../core/models/paged_result.dart';
import '../../domain/review.dart';

/// Estado da listagem de avaliações de um restaurante (DV-04), sealed
/// class. Prefixo `Reviews*` para evitar colisão com estados de outros
/// módulos (mesma lição do DV-01/DV-02/DV-03).
sealed class ReviewsStatus {
  const ReviewsStatus();
}

final class ReviewsInitial extends ReviewsStatus {
  const ReviewsInitial();
}

final class ReviewsLoading extends ReviewsStatus {
  const ReviewsLoading();
}

final class ReviewsLoaded extends ReviewsStatus {
  const ReviewsLoaded(this.result);

  final PagedResult<Review> result;
}

final class ReviewsEmpty extends ReviewsStatus {
  const ReviewsEmpty();
}

final class ReviewsError extends ReviewsStatus {
  const ReviewsError(this.message);

  final String message;
}
