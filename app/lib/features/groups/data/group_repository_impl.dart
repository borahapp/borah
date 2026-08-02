import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
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
      return rows.map(_mapRow).toList();
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

  Group _mapRow(Map<String, dynamic> row) {
    return Group(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      photoUrl: row['photo_url'] as String?,
      inviteCode: row['invite_code'] as String,
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
