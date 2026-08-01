import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../domain/group_ranking_entry.dart';
import '../domain/group_ranking_repository.dart';
import 'group_ranking_remote_datasource.dart';

class GroupRankingRepositoryImpl implements GroupRankingRepository {
  GroupRankingRepositoryImpl(this._datasource);

  final GroupRankingRemoteDatasource _datasource;

  @override
  Future<List<GroupRankingEntry>> listByGroup(String groupId) {
    return _guard(() async {
      final rows = await _datasource.listByGroup(groupId);

      final userIds = rows.map((r) => r['user_id'] as String).toList();
      final profileRows = await _datasource.fetchProfilesByIds(userIds);
      final profilesById = {
        for (final profile in profileRows) profile['id'] as String: profile,
      };

      return rows.map((row) {
        final userId = row['user_id'] as String;
        final profile = profilesById[userId];
        return GroupRankingEntry(
          userId: userId,
          fullName: profile?['full_name'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
          eventsCount: row['events_count'] as int,
          reviewsCount: row['reviews_count'] as int,
          averageScore: (row['average_score'] as num?)?.toDouble(),
        );
      }).toList();
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw GroupRankingRepositoryException(e.message);
    }
  }
}

final groupRankingRepositoryProvider = Provider<GroupRankingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GroupRankingRepositoryImpl(GroupRankingRemoteDatasource(client));
});
