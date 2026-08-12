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
      final profilesById = await _fetchProfilesById(
        pageRows.map((row) => row['user_id'] as String),
      );

      return PagedResult<Review>(
        items: pageRows.map((row) => _mapRow(row, profilesById)).toList(),
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
      final profilesById = await _fetchProfilesById(
        pageRows.map((row) => row['user_id'] as String),
      );

      return PagedResult<Review>(
        items: pageRows.map((row) => _mapRow(row, profilesById)).toList(),
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
      final profilesById = await _fetchProfilesById([row['user_id'] as String]);
      return _mapRow(row, profilesById);
    });
  }

  @override
  Future<Review> create({
    required String restaurantId,
    required String userId,
    required double rating,
    required double ambienceScore,
    required double serviceScore,
    required double foodScore,
    required double costBenefitScore,
    String? comment,
  }) {
    return _guard(() async {
      final row = await _datasource.insert({
        'restaurant_id': restaurantId,
        'user_id': userId,
        'rating': rating,
        'ambience_score': ambienceScore,
        'service_score': serviceScore,
        'food_score': foodScore,
        'cost_benefit_score': costBenefitScore,
        'comment': comment,
      });
      final profilesById = await _fetchProfilesById([userId]);
      return _mapRow(row, profilesById);
    });
  }

  @override
  Future<Review> update(
    String id, {
    required double rating,
    required double ambienceScore,
    required double serviceScore,
    required double foodScore,
    required double costBenefitScore,
    String? comment,
  }) {
    return _guard(() async {
      final row = await _datasource.updatePatch(id, {
        'rating': rating,
        'ambience_score': ambienceScore,
        'service_score': serviceScore,
        'food_score': foodScore,
        'cost_benefit_score': costBenefitScore,
        'comment': comment,
      });
      final profilesById = await _fetchProfilesById([row['user_id'] as String]);
      return _mapRow(row, profilesById);
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
      final profilesById = await _fetchProfilesById([row['user_id'] as String]);
      return _mapRow(row, profilesById);
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

  @override
  Future<List<String>> listRestaurantPhotos(
    String restaurantId, {
    int limit = 12,
  }) {
    return _guard(() async {
      final rows = await _datasource.listByRestaurant(
        restaurantId,
        page: 1,
        limit: 20,
      );

      final photos = <String>[];
      for (final row in rows) {
        if (photos.length >= limit) break;
        final photosCount = row['photos_count'] as int;
        if (photosCount == 0) continue;
        final reviewPhotos = await _datasource.listPhotoUrls(
          row['id'] as String,
        );
        photos.addAll(reviewPhotos);
      }
      return photos.length > limit ? photos.sublist(0, limit) : photos;
    });
  }

  /// Busca perfis em lote (dedup via `Set`) - nunca 1 consulta por review,
  /// mesmo padrão de `EventReviewRepositoryImpl.listByEvent`/
  /// `FeedRepositoryImpl._compose` (2B.3).
  Future<Map<String, Map<String, dynamic>>> _fetchProfilesById(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return const {};
    final rows = await _datasource.fetchProfilesByIds(ids);
    return {for (final row in rows) row['id'] as String: row};
  }

  Review _mapRow(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    final restaurant = row['restaurants'] as Map<String, dynamic>;
    final profile = profilesById[row['user_id']];
    return Review(
      id: row['id'] as String,
      restaurantId: row['restaurant_id'] as String,
      userId: row['user_id'] as String,
      rating: (row['rating'] as num).toDouble(),
      ambienceScore: (row['ambience_score'] as num?)?.toDouble(),
      serviceScore: (row['service_score'] as num?)?.toDouble(),
      foodScore: (row['food_score'] as num?)?.toDouble(),
      costBenefitScore: (row['cost_benefit_score'] as num?)?.toDouble(),
      comment: row['comment'] as String?,
      likesCount: row['likes_count'] as int,
      photosCount: row['photos_count'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      authorFullName: profile?['full_name'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
      restaurantName: restaurant['name'] as String?,
      restaurantCoverImage: restaurant['cover_image'] as String?,
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
