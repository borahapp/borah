import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST da tabela
/// `notification_preferences` (DV-09). `category` passou a ser parâmetro
/// (RC-03 Sprint 0 - F48) em vez de fixo em `'social'` - o banco já
/// suporta `'groups'` desde `20260801130000_add_group_event_notifications.sql`.
class NotificationPreferenceRemoteDatasource {
  NotificationPreferenceRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'notification_preferences';

  /// Ausência de linha = habilitado por padrão (modelo opt-out).
  Future<bool> fetchInAppEnabled(String userId, String category) async {
    final rows = await _client
        .from(_table)
        .select('in_app_enabled')
        .eq('user_id', userId)
        .eq('category', category);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? true : list.first['in_app_enabled'] as bool;
  }

  Future<void> upsertInAppEnabled(
    String userId,
    String category,
    bool enabled,
  ) {
    return _client.from(_table).upsert({
      'user_id': userId,
      'category': category,
      'in_app_enabled': enabled,
    }, onConflict: 'user_id,category');
  }
}
