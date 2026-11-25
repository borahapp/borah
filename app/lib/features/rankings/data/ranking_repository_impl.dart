import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../restaurants/data/restaurant_repository_impl.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../restaurants/domain/restaurant_repository.dart';
import '../domain/ranked_restaurant.dart';
import '../domain/ranking_repository.dart';
import '../domain/ranking_scope.dart';
import 'ranking_remote_datasource.dart';

/// `global` delega para `RestaurantRepository.listRanked` (não duplica a
/// construção de consulta já existente, mesma decisão original do
/// DV-05); `personal`/`group` usam o [RankingRemoteDatasource] próprio
/// deste módulo (Item F) - ver comentário dele para o porquê de cada um
/// não caber em `RestaurantRepository`.
class RankingRepositoryImpl implements RankingRepository {
  RankingRepositoryImpl(this._restaurantRepository, this._datasource);

  final RestaurantRepository _restaurantRepository;
  final RankingRemoteDatasource _datasource;

  @override
  Future<PagedResult<RankedRestaurant>> list({
    required RankingScope scope,
    String? groupId,
    String? userId,
    String? city,
    String? state,
    String? country,
    String? category,
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      switch (scope) {
        case RankingScope.global:
          final result = await _restaurantRepository.listRanked(
            city: city,
            state: state,
            country: country,
            category: category,
            page: page,
            limit: limit,
          );
          return PagedResult(
            items: result.items.map(_fromRestaurant).toList(),
            page: result.page,
            limit: result.limit,
            hasNextPage: result.hasNextPage,
          );

        case RankingScope.personal:
          final rows = await _datasource.listPersonal(
            userId: userId!,
            city: city,
            state: state,
            country: country,
            category: category,
            page: page,
            limit: limit,
          );
          return _pagedFromRows(rows, page, limit, _fromPersonalRow);

        case RankingScope.group:
          final offset = (page - 1) * limit;
          final rows = await _datasource.listByGroup(
            groupId: groupId!,
            city: city,
            state: state,
            country: country,
            category: category,
            limit: limit + 1,
            offset: offset,
          );
          return _pagedFromRows(rows, page, limit, _fromGroupRow);
      }
    });
  }

  PagedResult<RankedRestaurant> _pagedFromRows(
    List<Map<String, dynamic>> rows,
    int page,
    int limit,
    RankedRestaurant Function(Map<String, dynamic>) mapRow,
  ) {
    final hasNextPage = rows.length > limit;
    final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;
    return PagedResult(
      items: pageRows.map(mapRow).toList(),
      page: page,
      limit: limit,
      hasNextPage: hasNextPage,
    );
  }

  RankedRestaurant _fromRestaurant(Restaurant restaurant) {
    return RankedRestaurant(
      restaurantId: restaurant.id,
      name: restaurant.name,
      category: restaurant.category,
      city: restaurant.city,
      state: restaurant.state,
      country: restaurant.country,
      coverImage: restaurant.coverImage,
      // `listRanked` já filtra `average_rating is not null` - nunca
      // chega aqui nulo, mas o `?? 0` evita um `!` desnecessário.
      rating: restaurant.averageRating ?? 0,
      reviewsCount: restaurant.totalReviews,
    );
  }

  RankedRestaurant _fromPersonalRow(Map<String, dynamic> row) {
    final restaurant = row['restaurants'] as Map<String, dynamic>;
    return RankedRestaurant(
      restaurantId: restaurant['id'] as String,
      name: restaurant['name'] as String,
      category: restaurant['category'] as String,
      city: restaurant['city'] as String?,
      state: restaurant['state'] as String?,
      country: restaurant['country'] as String?,
      coverImage: restaurant['cover_image'] as String?,
      rating: (row['rating'] as num).toDouble(),
    );
  }

  RankedRestaurant _fromGroupRow(Map<String, dynamic> row) {
    return RankedRestaurant(
      restaurantId: row['restaurant_id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      city: row['city'] as String?,
      state: row['state'] as String?,
      country: row['country'] as String?,
      coverImage: row['cover_image'] as String?,
      rating: (row['average_rating'] as num).toDouble(),
      reviewsCount: (row['total_reviews'] as num).toInt(),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RestaurantRepositoryException catch (e) {
      throw RankingRepositoryException(e.message);
    } on PostgrestException catch (e) {
      throw RankingRepositoryException(e.message);
    }
  }
}

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  final restaurantRepository = ref.watch(restaurantRepositoryProvider);
  final datasource = RankingRemoteDatasource(ref.watch(supabaseClientProvider));
  return RankingRepositoryImpl(restaurantRepository, datasource);
});
