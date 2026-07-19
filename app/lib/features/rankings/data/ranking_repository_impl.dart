import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../../restaurants/data/restaurant_repository_impl.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../restaurants/domain/restaurant_repository.dart';
import '../domain/ranking_repository.dart';

/// Delega para `RestaurantRepository` (DV-03) - não há Storage/PostgREST
/// próprios deste módulo, apenas uma consulta ordenada já exposta por
/// `RestaurantRepository.listRanked`. Esta camada existe para isolar o
/// módulo de Rankings de um acoplamento direto da aplicação com o
/// repositório de Restaurantes (decisão do DV-05).
class RankingRepositoryImpl implements RankingRepository {
  RankingRepositoryImpl(this._restaurantRepository);

  final RestaurantRepository _restaurantRepository;

  @override
  Future<PagedResult<Restaurant>> listRanked({
    String? city,
    String? category,
    required int page,
    required int limit,
  }) {
    return _guard(
      () => _restaurantRepository.listRanked(
        city: city,
        category: category,
        page: page,
        limit: limit,
      ),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RestaurantRepositoryException catch (e) {
      throw RankingRepositoryException(e.message);
    }
  }
}

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  final restaurantRepository = ref.watch(restaurantRepositoryProvider);
  return RankingRepositoryImpl(restaurantRepository);
});
