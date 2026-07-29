import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST da tabela
/// `notification_preferences` (DV-09). Fixado na categoria `'social'` -
/// a única com evento real implementado (decisão 5/7 do DV-09); as demais
/// categorias existem apenas como estrutura de banco.
class NotificationPreferenceRemoteDatasource {
  NotificationPreferenceRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'notification_preferences';
  static const _category = 'social';

  /// Ausência de linha = habilitado por padrão (modelo opt-out).
  Future<bool> fetchInAppEnabled(String userId) async {
    final rows = await _client
        .from(_table)
        .select('in_app_enabled')
        .eq('user_id', userId)
        .eq('category', _category);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? true : list.first['in_app_enabled'] as bool;
  }

  Future<void> upsertInAppEnabled(String userId, bool enabled) {
    return _client.from(_table).upsert({
      'user_id': userId,
      'category': _category,
      'in_app_enabled': enabled,
    }, onConflict: 'user_id,category');
  }
}
