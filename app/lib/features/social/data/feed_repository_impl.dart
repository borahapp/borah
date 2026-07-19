import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../reviews/domain/review.dart';
import '../domain/feed_repository.dart';
import 'feed_remote_datasource.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._datasource);

  final FeedRemoteDatasource _datasource;

  @override
  Future<PagedResult<Review>> listForUser(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listForUser(
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

  /// Mapeamento próprio (duplica `ReviewRepositoryImpl._mapRow`) - mesma
  /// decisão consciente do DV-06/DV-07: manter `features/social`
  /// desacoplado de `ReviewRepository`.
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
      throw FeedRepositoryException(e.message);
    }
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FeedRepositoryImpl(FeedRemoteDatasource(client));
});
