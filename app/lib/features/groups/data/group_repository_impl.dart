import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../domain/event_summary.dart';
import '../domain/group.dart';
import '../domain/group_details.dart';
import '../domain/group_member.dart';
import '../domain/group_repository.dart';
import 'group_remote_datasource.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._datasource);

  final GroupRemoteDatasource _datasource;

  @override
  Future<Group> create({
    required String name,
    String? description,
    String? photoUrl,
  }) {
    return _guard(() async {
      final row = await _datasource.createGroup(
        name: name,
        description: description,
        photoUrl: photoUrl,
      );
      return _mapRow(row);
    });
  }

  @override
  Future<List<Group>> listMine() {
    return _guard(() async {
      final rows = await _datasource.listMine();
      final groupIds = rows.map((row) => row['id'] as String).toList();
      final eventRows = await _datasource.fetchNextEvents(groupIds);

      // Sprint 3 (F46): `eventRows` já vem ordenado ascendente por
      // `scheduled_at` (ver `fetchNextEvents`) - `putIfAbsent` mantém só
      // a primeira ocorrência de cada `group_id`, ou seja, a mais próxima.
      final nextEventByGroupId = <String, EventSummary>{};
      for (final eventRow in eventRows) {
        nextEventByGroupId.putIfAbsent(
          eventRow['group_id'] as String,
          () => EventSummary(
            id: eventRow['id'] as String,
            scheduledAt: DateTime.parse(eventRow['scheduled_at'] as String),
          ),
        );
      }

      return rows
          .map(
            (row) => _mapRow(
              row,
              nextEvent: nextEventByGroupId[row['id'] as String],
            ),
          )
          .toList();
    });
  }

  @override
  Future<GroupDetails> getById(String id) {
    return _guard(() async {
      final groupRow = await _datasource.fetchGroupById(id);
      final memberRows = await _datasource.fetchMembers(id);

      final userIds = memberRows.map((m) => m['user_id'] as String).toList();
      final profileRows = await _datasource.fetchProfilesByIds(userIds);
      final profilesById = {
        for (final profile in profileRows) profile['id'] as String: profile,
      };

      final members = memberRows.map((memberRow) {
        final userId = memberRow['user_id'] as String;
        final profile = profilesById[userId];
        return GroupMember(
          id: memberRow['id'] as String,
          userId: userId,
          role: memberRow['role'] as String,
          fullName: profile?['full_name'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
        );
      }).toList();

      return GroupDetails(group: _mapRow(groupRow), members: members);
    });
  }

  @override
  Future<Group> joinByInviteCode(String inviteCode) {
    return _guard(() async {
      final row = await _datasource.joinByInviteCode(inviteCode);
      return _mapRow(row);
    });
  }

  @override
  Future<Group> update({
    required String id,
    required String name,
    String? description,
    String? photoUrl,
  }) {
    return _guard(() async {
      final row = await _datasource.updateGroup(
        id: id,
        name: name,
        description: description,
        photoUrl: photoUrl,
      );
      return _mapRow(row);
    });
  }

  @override
  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) {
    return _guard(() => _datasource.updateMemberRole(memberId, role));
  }

  @override
  Future<void> removeMember(String memberId) {
    return _guard(() => _datasource.removeMember(memberId));
  }

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerMemberId,
  }) {
    return _guard(
      () => _datasource.transferOwnership(groupId, newOwnerMemberId),
    );
  }

  @override
  Future<void> delete(String groupId) {
    return _guard(() => _datasource.deleteGroup(groupId));
  }

  @override
  Future<List<Group>> listCommonGroups(
    String currentUserId,
    String otherUserId,
  ) {
    return _guard(() async {
      final groupIds = await _datasource.fetchCommonGroupIds(
        currentUserId,
        otherUserId,
      );
      if (groupIds.isEmpty) return [];
      final rows = await _datasource.fetchGroupsByIds(groupIds);
      return rows.map((row) => _mapRow(row)).toList();
    });
  }

  /// [nextEvent] só é conhecido por `listMine()` (única chamadora que
  /// busca `fetchNextEvents` em lote) - os demais métodos usam o valor
  /// padrão `null`. `group_members` só existe na linha quando o `select`
  /// pediu o embed (hoje, só `listMine()` pede); ausente nos outros,
  /// `memberCount` fica `null` para eles.
  Group _mapRow(Map<String, dynamic> row, {EventSummary? nextEvent}) {
    final memberRows = row['group_members'] as List?;
    final memberCount = memberRows != null && memberRows.isNotEmpty
        ? memberRows.first['count'] as int
        : null;

    return Group(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      photoUrl: row['photo_url'] as String?,
      inviteCode: row['invite_code'] as String,
      memberCount: memberCount,
      nextEvent: nextEvent,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw GroupRepositoryException(e.message);
    }
  }
}

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GroupRepositoryImpl(GroupRemoteDatasource(client));
});
