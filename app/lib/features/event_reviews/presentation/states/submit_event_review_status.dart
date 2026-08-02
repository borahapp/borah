import '../../domain/event_review.dart';

/// Estado de enviar/editar uma avaliação coletiva (BLOCO 4) - mesmo
/// padrão de `CreateEventStatus`: sealed class, uma operação única por
/// tela (sem "load" - a tela recebe a avaliação existente, se houver,
/// via `extra` da rota, mesmo padrão de `EditGroupPage`).
sealed class SubmitEventReviewStatus {
  const SubmitEventReviewStatus();
}

final class SubmitEventReviewInitial extends SubmitEventReviewStatus {
  const SubmitEventReviewInitial();
}

final class SubmitEventReviewSaving extends SubmitEventReviewStatus {
  const SubmitEventReviewSaving();
}

final class SubmitEventReviewSaveSuccess extends SubmitEventReviewStatus {
  const SubmitEventReviewSaveSuccess(this.review);

  final EventReview review;
}

final class SubmitEventReviewError extends SubmitEventReviewStatus {
  const SubmitEventReviewError(this.message);

  final String message;
}
