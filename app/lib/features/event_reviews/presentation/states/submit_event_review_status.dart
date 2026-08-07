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
  const SubmitEventReviewSaveSuccess(this.review, {this.photoWarning});

  final EventReview review;

  /// Não-nulo quando a avaliação (notas/comentário) foi salva com
  /// sucesso, mas o anexo/remoção da foto falhou (RC-03 FASE A2) - a
  /// nota do usuário nunca é perdida por causa de uma falha na parte
  /// opcional do formulário (`BORAH_VISION_v2.0.md`, Princípio 3: foto
  /// é sempre opcional). A tela mostra isso como um aviso secundário,
  /// não como erro do envio inteiro.
  final String? photoWarning;
}

final class SubmitEventReviewError extends SubmitEventReviewStatus {
  const SubmitEventReviewError(this.message);

  final String message;
}
