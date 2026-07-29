/// Entidade de comentário (DV-07 §9) — preso diretamente a uma avaliação
/// (`reviewId`), não a um "post" de evento como o ET-09 (Draft) modela.
/// Segue o mesmo padrão de resolução já aplicado ao ET-08/DV-04.
class Comment {
  const Comment({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String reviewId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
}
