/// Restaurante próximo à localização atual do usuário (Item G - sugestão
/// por localização em Explorar), via `get_nearby_restaurants` (SQL).
/// Entidade própria (não `Restaurant`) porque carrega `distanceKm`, algo
/// que só faz sentido no contexto desta consulta.
class NearbyRestaurant {
  const NearbyRestaurant({
    required this.restaurantId,
    required this.name,
    required this.category,
    this.city,
    this.coverImage,
    this.averageRating,
    required this.totalReviews,
    required this.distanceKm,
  });

  final String restaurantId;
  final String name;
  final String category;
  final String? city;
  final String? coverImage;
  final double? averageRating;
  final int totalReviews;
  final double distanceKm;
}
