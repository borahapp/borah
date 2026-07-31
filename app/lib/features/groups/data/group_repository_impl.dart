import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../domain/group.dart';
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
