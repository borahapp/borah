import '../../domain/event_review.dart';

/// Estado da lista de avaliações coletivas de um rolê (BLOCO 4), sealed
/// class - mesmo padrão de `EventsListStatus`.
sealed class EventReviewsStatus {
  const EventReviewsStatus();
}

final class EventReviewsInitial extends EventReviewsStatus {
  const EventReviewsInitial();
}

final class EventReviewsLoading extends EventReviewsStatus {
  const EventReviewsLoading();
}

final class EventReviewsLoaded extends EventReviewsStatus {
  const EventReviewsLoaded(this.reviews);

  final List<EventReview> reviews;
}

final class EventReviewsEmpty extends EventReviewsStatus {
  const EventReviewsEmpty();
}

final class EventReviewsError extends EventReviewsStatus {
  const EventReviewsError(this.message);

  final String message;
}
