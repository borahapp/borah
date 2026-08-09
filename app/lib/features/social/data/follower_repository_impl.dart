import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../users/domain/user_profile.dart';
import '../domain/follower_repository.dart';
import 'follower_remote_datasource.dart';

class FollowerRepositoryImpl implements FollowerRepository {
  FollowerRepositoryImpl(this._datasource);

  final FollowerRemoteDatasource _datasource;

  @override
  Future<void> follow(String followerId, String followingId) {
    return _guard(() => _datasource.follow(followerId, followingId));
  }

  @override
  Future<void> unfollow(String followerId, String followingId) {
    return _guard(() => _datasource.unfollow(followerId, followingId));
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) {
    return _guard(() => _datasource.isFollowing(followerId, followingId));
  }

  @override
  Future<PagedResult<UserProfile>> listFollowers(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _guard(
      () => _listByIds(
        () => _datasource.listFollowerIds(userId, page: page, limit: limit),
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  Future<PagedResult<UserProfile>> listFollowing(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _guard(
      () => _listByIds(
        () => _datasource.listFollowingIds(userId, page: page, limit: limit),
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  Future<PagedResult<UserProfile>> searchProfiles(
    String query, {
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.searchProfiles(
        query,
        page: page,
        limit: limit,
      );
      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;
      return PagedResult<UserProfile>(
        items: pageRows.map(_mapRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  Future<PagedResult<UserProfile>> _listByIds(
    Future<List<String>> Function() fetchIds, {
    required int page,
    required int limit,
  }) async {
    final ids = await fetchIds();
    final hasNextPage = ids.length > limit;
    final pageIds = hasNextPage ? ids.sublist(0, limit) : ids;

    final rows = await _datasource.fetchProfilesByIds(pageIds);
    final rowsById = {for (final row in rows) row['id'] as String: row};
    // Preserva a ordem de `pageIds` (mais recente primeiro) - `inFilter`
    // não garante ordem correspondente.
    final profiles = pageIds
        .where(rowsById.containsKey)
        .map((id) => _mapRow(rowsById[id]!))
        .toList();

    return PagedResult<UserProfile>(
      items: profiles,
      page: page,
      limit: limit,
      hasNextPage: hasNextPage,
    );
  }

  /// Mapeamento próprio (duplica `UserProfileRepositoryImpl._mapRow`) -
  /// mesma decisão consciente do DV-06 (`_mapRestaurantRow`): manter
  /// `features/social` desacoplado de `UserProfileRepository`.
  UserProfile _mapRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      fullName: row['full_name'] as String?,
      bio: row['bio'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      city: row['city'] as String?,
      state: row['state'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw FollowerRepositoryException(e.message);
    }
  }
}

final followerRepositoryProvider = Provider<FollowerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FollowerRepositoryImpl(FollowerRemoteDatasource(client));
});
