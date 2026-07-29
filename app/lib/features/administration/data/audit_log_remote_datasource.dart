import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST da tabela
/// `audit_logs` (DV-08) - append-only, nunca update/delete.
class AuditLogRemoteDatasource {
  AuditLogRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'audit_logs';

  Future<void> insert(Map<String, dynamic> data) {
    return _client.from(_table).insert(data);
  }

  Future<List<Map<String, dynamic>>> listRecent({
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }
}
