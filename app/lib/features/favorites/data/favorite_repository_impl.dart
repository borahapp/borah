import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../restaurants/domain/restaurant.dart';
import '../domain/favorite_repository.dart';
import '../domain/favorite_sort_by.dart';
import 'favorite_remote_datasource.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(this._datasource);

  final FavoriteRemoteDatasource _datasource;

  @override
  Future<PagedResult<Restaurant>> listForUser(
    String userId, {
    String? query,
    String? city,
    String? category,
    required FavoriteSortBy sortBy,
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listForUser(
        userId,
        query: query,
        city: city,
        category: category,
        sortBy: sortBy,
        page: page,
        limit: limit,
      );

      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      return PagedResult<Restaurant>(
        items: pageRows.map(_mapRestaurantRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  @override
  Future<void> addFavorite(String userId, String restaurantId) {
    return _guard(() => _datasource.addFavorite(userId, restaurantId));
  }

  @override
  Future<void> removeFavorite(String userId, String restaurantId) {
    return _guard(() => _datasource.removeFavorite(userId, restaurantId));
  }

  @override
  Future<bool> isFavorited(String userId, String restaurantId) {
    return _guard(() => _datasource.isFavorited(userId, restaurantId));
  }

  /// Mapeamento próprio (duplica `RestaurantRepositoryImpl._mapRow`) -
  /// decisão consciente do DV-06: manter os dois módulos desacoplados em
  /// vez de depender de `RestaurantRepository` só para reaproveitar este
  /// mapeamento. O formato da linha vem do embed `restaurants!inner(*)`.
  Restaurant _mapRestaurantRow(Map<String, dynamic> row) {
    final restaurantRow = row['restaurants'] as Map<String, dynamic>;
    return Restaurant(
      id: restaurantRow['id'] as String,
      name: restaurantRow['name'] as String,
      category: restaurantRow['category'] as String,
      description: restaurantRow['description'] as String?,
      address: restaurantRow['address'] as String?,
      city: restaurantRow['city'] as String?,
      state: restaurantRow['state'] as String?,
      latitude: (restaurantRow['latitude'] as num?)?.toDouble(),
      longitude: (restaurantRow['longitude'] as num?)?.toDouble(),
      averageRating: (restaurantRow['average_rating'] as num?)?.toDouble(),
      totalReviews: restaurantRow['total_reviews'] as int,
      coverImage: restaurantRow['cover_image'] as String?,
      status: restaurantRow['status'] as String,
      createdBy: restaurantRow['created_by'] as String,
      createdAt: DateTime.parse(restaurantRow['created_at'] as String),
      updatedAt: DateTime.parse(restaurantRow['updated_at'] as String),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw FavoriteRepositoryException(e.message);
    }
  }
}

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FavoriteRepositoryImpl(FavoriteRemoteDatasource(client));
});
