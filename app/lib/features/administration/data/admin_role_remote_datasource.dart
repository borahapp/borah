import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST da tabela
/// `user_roles` e a resolução de nomes em `profiles` (DV-08). `user_roles`
/// referencia `auth.users`, não `profiles` - mesma limitação de embed já
/// resolvida no DV-07 (`FollowerRemoteDatasource`), mesmo padrão de duas
/// consultas aplicado aqui.
class AdminRoleRemoteDatasource {
  AdminRoleRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'user_roles';
  static const _profilesTable = 'profiles';

  Future<String?> fetchRole(String userId) async {
    final rows = await _client
        .from(_table)
        .select('role')
        .eq('user_id', userId);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? null : list.first['role'] as String;
  }

  Future<List<Map<String, dynamic>>> listAdmins({
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;
    final rows = await _client
        .from(_table)
        .select('user_id, role')
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, String?>> fetchNamesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _client
        .from(_profilesTable)
        .select('id, full_name')
        .inFilter('id', ids);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['id'] as String: row['full_name'] as String?,
    };
  }

  /// `onConflict: 'user_id'` - o conflito deve ser resolvido pela
  /// constraint `UNIQUE(user_id)`, não pela PK `id` (padrão do upsert).
  Future<void> grantRole(String userId, String role) {
    return _client.from(_table).upsert({
      'user_id': userId,
      'role': role,
    }, onConflict: 'user_id');
  }

  Future<void> revokeRole(String userId) {
    return _client.from(_table).delete().eq('user_id', userId);
  }
}
