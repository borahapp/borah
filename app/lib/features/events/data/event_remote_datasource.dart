import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula todo acesso a `events`/`event_attendances` via PostgREST
/// (ROLÊ-02/ROLÊ-03).
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

  static const _eventsTable = 'events';
  static const _attendancesTable = 'event_attendances';
  static const _profilesTable = 'profiles';

  static const _eventColumns =
      'id,group_id,restaurant_id,scheduled_at,status,'
      'restaurants(name,category,city)';

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

  /// ROLÊ-03: embed direto com `restaurants` - `events.restaurant_id` é
  /// FK real para `restaurants.id` (`on delete restrict`), diferente do
  /// caso `group_members`/`profiles` (sem FK). Mesmo padrão de
  /// `FavoriteRemoteDatasource` (`restaurants!inner(*)`). A policy
  /// `events_select_members` (ROLÊ-01) já restringe as linhas aos
  /// grupos do usuário autenticado.
  Future<List<Map<String, dynamic>>> listByGroup(String groupId) async {
    final rows = await _client
        .from(_eventsTable)
        .select(_eventColumns)
        .eq('group_id', groupId)
        .order('scheduled_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> fetchEventById(String eventId) {
    return _client
        .from(_eventsTable)
        .select(_eventColumns)
        .eq('id', eventId)
        .single();
  }

  /// Sem embed com `profiles` - mesma limitação de
  /// `GroupRemoteDatasource.fetchMembers` (sem FK direta).
  Future<List<Map<String, dynamic>>> fetchAttendances(String eventId) async {
    final rows = await _client
        .from(_attendancesTable)
        .select('id,user_id,status')
        .eq('event_id', eventId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Mesmo método/assinatura de `GroupRemoteDatasource.fetchProfilesByIds`
  /// - duplicado aqui em vez de compartilhado entre features, mesma
  /// decisão já tomada para `FollowerRemoteDatasource`/
  /// `GroupRemoteDatasource` (nenhuma base comum entre datasources).
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_profilesTable)
        .select()
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Atualiza a própria presença por `id` da linha - a RLS
  /// (`event_attendances_update_own`) garante que só a própria linha é
  /// afetada, mesmo padrão de `update(...).eq('id', id)` sem filtro
  /// redundante de usuário já usado em
  /// `CommentRemoteDatasource`/`ReviewRemoteDatasource`.
  Future<void> updateAttendanceStatus(String attendanceId, String status) {
    return _client
        .from(_attendancesTable)
        .update({'status': status})
        .eq('id', attendanceId);
  }
}
