/// Entidade de restaurante (DV-03 §9), incluindo os campos de preparação
/// para evolução futura (`status`, `deletedAt`) - nenhuma lógica de
/// moderação ou exclusão lógica é aplicada sobre eles nesta etapa.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.address,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.averageRating,
    required this.totalReviews,
    this.coverImage,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final double? averageRating;
  final int totalReviews;
  final String? coverImage;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}
