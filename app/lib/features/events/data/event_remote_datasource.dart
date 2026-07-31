import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula a chamada RPC de criação de rolê (ROLÊ-02).
///
/// `create_event()` é uma função Postgres `SECURITY DEFINER`
/// (migration `20260731092000_create_events_and_attendances.sql`) -
/// cria o evento, insere a presença de cada membro atual do grupo
/// (organizador confirmado, demais pendentes) e atualiza
/// `groups.last_activity_at`, tudo na mesma transação. Nenhuma regra de
/// negócio existe aqui nem em nenhuma camada acima - só repassa os 3
/// parâmetros. Nomes (`p_group_id`/`p_restaurant_id`/`p_scheduled_at`)
/// precisam bater exatamente com a assinatura da função.
class EventRemoteDatasource {
  EventRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> createEvent({
    required String groupId,
    required String restaurantId,
    required DateTime scheduledAt,
  }) async {
    final result = await _client.rpc(
      'create_event',
      params: {
        'p_group_id': groupId,
        'p_restaurant_id': restaurantId,
        'p_scheduled_at': scheduledAt.toIso8601String(),
      },
    );
    return result as Map<String, dynamic>;
  }
}
