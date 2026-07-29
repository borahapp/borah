/// Parâmetros de busca (DV-03 §4/§11) — a camada de aplicação monta este
/// objeto simples; a construção da consulta Postgrest fica isolada em
/// `data/` (o controller nunca conhece esses detalhes).
class RestaurantSearchFilters {
  const RestaurantSearchFilters({
    this.query,
    this.city,
    this.category,
    this.page = 1,
    this.limit = 20,
  });

  final String? query;
  final String? city;
  final String? category;
  final int page;
  final int limit;

  RestaurantSearchFilters copyWith({
    String? query,
    String? city,
    String? category,
    int? page,
  }) {
    return RestaurantSearchFilters(
      query: query ?? this.query,
      city: city ?? this.city,
      category: category ?? this.category,
      page: page ?? this.page,
      limit: limit,
    );
  }
}
