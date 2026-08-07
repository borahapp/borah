import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/gamification_badge.dart';
import '../domain/gamification_repository.dart';
import '../domain/groups_activity_summary.dart';
import '../domain/ranking_entry.dart';
import '../domain/user_progress.dart';
import 'gamification_remote_datasource.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  GamificationRepositoryImpl(this._datasource);

  final GamificationRemoteDatasource _datasource;

  @override
  Future<UserProgress> getProgress(String userId) {
    return _guard(() async {
      final row = await _datasource.fetchProgress(userId);
      if (row == null) {
        return UserProgress(
          userId: userId,
          xp: 0,
          points: 0,
          level: 1,
          updatedAt: DateTime.now(),
        );
      }
      return _mapProgressRow(row);
    });
  }

  @override
  Future<List<GamificationBadge>> listAllBadges() {
    return _guard(() async {
      final rows = await _datasource.listAllBadges();
      return rows.map(_mapBadgeRow).toList();
    });
  }

  @override
  Future<List<EarnedBadge>> listEarnedBadges(String userId) {
    return _guard(() async {
      final rows = await _datasource.listEarnedBadges(userId);
      return rows
          .map(
            (row) => EarnedBadge(
              badge: _mapBadgeRow(row['badges'] as Map<String, dynamic>),
              earnedAt: DateTime.parse(row['earned_at'] as String),
            ),
          )
          .toList();
    });
  }

  @override
  Future<PagedResult<RankingEntry>> listGlobalRanking({
    required int page,
    required int limit,
  }) {
    return _guard(
      () => _buildRanking(
        () => _datasource.listGlobalRanking(page: page, limit: limit),
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  Future<PagedResult<RankingEntry>> listFriendsRanking(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _guard(
      () => _buildRanking(
        () => _datasource.listFriendsRanking(userId, page: page, limit: limit),
        page: page,
        limit: limit,
      ),
    );
  }

  Future<PagedResult<RankingEntry>> _buildRanking(
    Future<List<Map<String, dynamic>>> Function() fetchRows, {
    required int page,
    required int limit,
  }) async {
    final rows = await fetchRows();
    final hasNextPage = rows.length > limit;
    final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

    final ids = pageRows.map((row) => row['user_id'] as String).toList();
    final names = await _datasource.fetchNamesByIds(ids);

    final entries = pageRows
        .map(
          (row) => RankingEntry(
            progress: _mapProgressRow(row),
            fullName: names[row['user_id'] as String],
          ),
        )
        .toList();

    return PagedResult<RankingEntry>(
      items: entries,
      page: page,
      limit: limit,
      hasNextPage: hasNextPage,
    );
  }

  @override
  Future<GroupsActivitySummary> getGroupsActivitySummary(String userId) {
    return _guard(() async {
      final rows = await _datasource.fetchGroupMembershipCounts(userId);
      var eventsCount = 0;
      var reviewsCount = 0;
      for (final row in rows) {
        eventsCount += row['events_count'] as int;
        reviewsCount += row['reviews_count'] as int;
      }
      return GroupsActivitySummary(
        eventsCount: eventsCount,
        reviewsCount: reviewsCount,
      );
    });
  }

  UserProgress _mapProgressRow(Map<String, dynamic> row) {
    return UserProgress(
      userId: row['user_id'] as String,
      xp: row['xp'] as int,
      points: row['points'] as int,
      level: row['level'] as int,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  GamificationBadge _mapBadgeRow(Map<String, dynamic> row) {
    return GamificationBadge(
      id: row['id'] as String,
      code: row['code'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw GamificationRepositoryException(e.message);
    }
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GamificationRepositoryImpl(GamificationRemoteDatasource(client));
});
