import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._datasource);

  final ReviewRemoteDatasource _datasource;

  @override
  Future<PagedResult<Review>> listByRestaurant(
    String restaurantId, {
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listByRestaurant(
        restaurantId,
        page: page,
        limit: limit,
      );

      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      return PagedResult<Review>(
        items: pageRows.map(_mapRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  @override
  Future<PagedResult<Review>> listByUser(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listByUser(
        userId,
        page: page,
        limit: limit,
      );

      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      return PagedResult<Review>(
        items: pageRows.map(_mapRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  @override
  Future<Review> getById(String id) {
    return _guard(() async {
      final row = await _datasource.fetchById(id);
      return _mapRow(row);
    });
  }

  @override
  Future<Review> create({
    required String restaurantId,
    required String userId,
    required double rating,
    String? comment,
  }) {
    return _guard(() async {
      final row = await _datasource.insert({
        'restaurant_id': restaurantId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      });
      return _mapRow(row);
    });
  }

  @override
  Future<Review> update(String id, {required double rating, String? comment}) {
    return _guard(() async {
      final row = await _datasource.updatePatch(id, {
        'rating': rating,
        'comment': comment,
      });
      return _mapRow(row);
    });
  }

  @override
  Future<void> delete(String id) {
    return _guard(() => _datasource.softDelete(id));
  }

  /// Mesma operação de `delete` - a diferença está inteiramente na RLS
  /// (policy de admin criada no DV-08 permite isso para qualquer
  /// avaliação, não só a do próprio autor). Nomeado separadamente por
  /// clareza de intenção na camada de aplicação.
  @override
  Future<void> hideAsAdmin(String id) {
    return _guard(() => _datasource.softDelete(id));
  }

  @override
  Future<Review> addPhoto(
    String id, {
    required Uint8List bytes,
    required String fileExtension,
  }) {
    return _guard(() async {
      await _datasource.uploadPhoto(id, bytes, fileExtension);
      final current = await _datasource.fetchById(id);
      final newCount = (current['photos_count'] as int) + 1;
      final row = await _datasource.updatePatch(id, {'photos_count': newCount});
      return _mapRow(row);
    });
  }

  @override
  Future<List<String>> listPhotoUrls(String reviewId) {
    return _guard(() => _datasource.listPhotoUrls(reviewId));
  }

  @override
  Future<void> like(String reviewId, String userId) {
    return _guard(() => _datasource.like(reviewId, userId));
  }

  @override
  Future<void> unlike(String reviewId, String userId) {
    return _guard(() => _datasource.unlike(reviewId, userId));
  }

  @override
  Future<bool> isLikedByUser(String reviewId, String userId) {
    return _guard(() => _datasource.isLikedByUser(reviewId, userId));
  }

  Review _mapRow(Map<String, dynamic> row) {
    return Review(
      id: row['id'] as String,
      restaurantId: row['restaurant_id'] as String,
      userId: row['user_id'] as String,
      rating: (row['rating'] as num).toDouble(),
      comment: row['comment'] as String?,
      likesCount: row['likes_count'] as int,
      photosCount: row['photos_count'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw ReviewRepositoryException(e.message);
    } on StorageException catch (e) {
      throw ReviewRepositoryException(e.message);
    }
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReviewRepositoryImpl(ReviewRemoteDatasource(client));
});
