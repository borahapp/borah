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
    this.country,
    this.latitude,
    this.longitude,
    this.averageRating,
    required this.totalReviews,
    this.coverImage,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.googlePlaceId,
  });

  final String id;
  final String name;
  final String category;
  final String? description;
  final String? address;
  final String? city;
  final String? state;

  /// Item F (ranking multi-escopo) - nullable, mesma limitação de
  /// `city`/`state`: nenhum backfill, nenhuma extração automática do
  /// fluxo Google Places (que hoje não analisa componentes estruturados
  /// de endereço) - só preenchido quando alguém digita no cadastro
  /// manual (`CreateRestaurantPage`).
  final String? country;
  final double? latitude;
  final double? longitude;
  final double? averageRating;
  final int totalReviews;
  final String? coverImage;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// F12 - `places.id` da Google Places API (New), quando o restaurante
  /// foi criado a partir de uma busca real. `null` para restaurantes
  /// cadastrados manualmente (todos os pré-existentes, e qualquer novo
  /// via `CreateRestaurantPage`) - nunca obrigatório, nunca retroativo.
  final String? googlePlaceId;
}
