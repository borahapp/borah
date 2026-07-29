import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST da tabela
/// `notifications` (DV-09). Nenhum método de inserção aqui - o cliente
/// não tem permissão de INSERT (decisão 4 do DV-09), só os triggers do
/// banco escrevem.
class NotificationRemoteDatasource {
  NotificationRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'notifications';

  /// Busca `limit + 1` registros para permitir detectar se há próxima
  /// página sem depender de uma contagem exata (core/models/paged_result.dart).
  Future<List<Map<String, dynamic>>> listForUser(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markAsRead(String id) {
    return _client
        .from(_table)
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  /// Atualiza apenas as notificações ainda não lidas (decisão 8 do DV-09).
  Future<void> markAllAsRead(String userId) {
    return _client
        .from(_table)
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}
