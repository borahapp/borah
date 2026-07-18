import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/restaurant.dart';
import '../domain/restaurant_repository.dart';
import '../domain/restaurant_search_filters.dart';
import 'restaurant_remote_datasource.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  RestaurantRepositoryImpl(this._datasource);

  final RestaurantRemoteDatasource _datasource;

  @override
  Future<PagedResult<Restaurant>> search(RestaurantSearchFilters filters) {
    return _guard(() async {
      final rows = await _datasource.search(
        query: filters.query,
        city: filters.city,
        category: filters.category,
        page: filters.page,
        limit: filters.limit,
      );

      final hasNextPage = rows.length > filters.limit;
      final pageRows = hasNextPage ? rows.sublist(0, filters.limit) : rows;

      return PagedResult<Restaurant>(
        items: pageRows.map(_mapRow).toList(),
        page: filters.page,
        limit: filters.limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  @override
  Future<Restaurant> getById(String id) {
    return _guard(() async {
      final row = await _datasource.fetchById(id);
      return _mapRow(row);
    });
  }

  @override
  Future<Restaurant> create({
    required String createdBy,
    required String name,
    required String category,
    String? description,
    String? address,
    String? city,
    String? stateProvince,
    double? latitude,
    double? longitude,
  }) {
    return _guard(() async {
      final row = await _datasource.insert({
        'created_by': createdBy,
        'name': name,
        'category': category,
        'description': description,
        'address': address,
        'city': city,
        'state': stateProvince,
        'latitude': latitude,
        'longitude': longitude,
      });
      return _mapRow(row);
    });
  }

  @override
  Future<Restaurant> updateCoverImage(
    String restaurantId, {
    required Uint8List bytes,
    required String fileExtension,
  }) {
    return _guard(() async {
      final path = await _datasource.uploadCoverImage(
        restaurantId,
        bytes,
        fileExtension,
      );
      final row = await _datasource.updatePatch(restaurantId, {
        'cover_image': path,
      });
      return _mapRow(row);
    });
  }

  Restaurant _mapRow(Map<String, dynamic> row) {
    return Restaurant(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      description: row['description'] as String?,
      address: row['address'] as String?,
      city: row['city'] as String?,
      state: row['state'] as String?,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      averageRating: (row['average_rating'] as num?)?.toDouble(),
      totalReviews: row['total_reviews'] as int,
      coverImage: row['cover_image'] as String?,
      status: row['status'] as String,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw RestaurantRepositoryException(e.message);
    } on StorageException catch (e) {
      throw RestaurantRepositoryException(e.message);
    }
  }
}

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RestaurantRepositoryImpl(RestaurantRemoteDatasource(client));
});
