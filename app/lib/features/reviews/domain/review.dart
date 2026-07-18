/// Entidade de avaliação (DV-04 §9) — avaliação por restaurante, sem
/// vínculo com evento (decisão que ignora o modelo do ET-08).
class Review {
  const Review({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.likesCount,
    required this.photosCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String restaurantId;
  final String userId;
  final double rating;
  final String? comment;
  final int likesCount;
  final int photosCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}
