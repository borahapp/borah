import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/admin_role_repository.dart';
import 'admin_role_remote_datasource.dart';

class AdminRoleRepositoryImpl implements AdminRoleRepository {
  AdminRoleRepositoryImpl(this._datasource);

  final AdminRoleRemoteDatasource _datasource;

  @override
  Future<String?> getRole(String userId) {
    return _guard(() => _datasource.fetchRole(userId));
  }

  @override
  Future<PagedResult<AdminRoleEntry>> listAdmins({
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listAdmins(page: page, limit: limit);
      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      final ids = pageRows.map((row) => row['user_id'] as String).toList();
      final names = await _datasource.fetchNamesByIds(ids);

      final entries = pageRows
          .map(
            (row) => AdminRoleEntry(
              userId: row['user_id'] as String,
              role: row['role'] as String,
              fullName: names[row['user_id'] as String],
            ),
          )
          .toList();

      return PagedResult<AdminRoleEntry>(
        items: entries,
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  @override
  Future<void> grantRole(String userId, String role) {
    return _guard(() => _datasource.grantRole(userId, role));
  }

  @override
  Future<void> revokeRole(String userId) {
    return _guard(() => _datasource.revokeRole(userId));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw AdminRoleRepositoryException(e.message);
    }
  }
}

final adminRoleRepositoryProvider = Provider<AdminRoleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminRoleRepositoryImpl(AdminRoleRemoteDatasource(client));
});
