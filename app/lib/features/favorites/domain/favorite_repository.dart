import '../../../core/models/paged_result.dart';
import '../../restaurants/domain/restaurant.dart';
import 'favorite_sort_by.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class FavoriteRepositoryException implements Exception {
  const FavoriteRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Favoritos (DV-06). Reaproveita a entidade
/// `Restaurant` (sem uma entidade `Favorite` própria) - a lista de
/// favoritos é sempre uma lista de restaurantes. Diferente do
/// `RankingRepository` (DV-05), este módulo NÃO delega para
/// `RestaurantRepository`: a consulta usa embed do PostgREST
/// (`restaurants!inner(*)`) diretamente em `data/`, evitando N+1 sem
/// acoplar os dois módulos (decisão do DV-06).
abstract interface class FavoriteRepository {
  Future<PagedResult<Restaurant>> listForUser(
    String userId, {
    String? query,
    String? city,
    String? category,
    required FavoriteSortBy sortBy,
    required int page,
    required int limit,
  });

  Future<void> addFavorite(String userId, String restaurantId);

  Future<void> removeFavorite(String userId, String restaurantId);

  Future<bool> isFavorited(String userId, String restaurantId);
}
