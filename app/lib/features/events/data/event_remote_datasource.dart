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
      'id,group_id,restaurant_id,organizer_id,scheduled_at,status,average_rating,total_reviews,'
      'restaurants(name,category,city,cover_image),event_attendances(count)';

  /// Filtro aplicado ao embed `event_attendances(count)` de
  /// [_eventColumns] em toda consulta que o usa (FASE B0,
  /// `EventCard.confirmedCount`) - sem isto, o embed contaria TODAS as
  /// presenças (confirmadas/pendentes/recusadas), não só as
  /// confirmadas. Mesma técnica de `group_members(count)`
  /// (`GroupRemoteDatasource`, Sprint 3), com um filtro a mais no path
  /// do embed - sintaxe validada contra o projeto QA real via HTTP
  /// direto antes de escrever este código (`select=...,
  /// event_attendances(count)&event_attendances.status=eq.confirmed`
  /// retornou 200, não 400).
  static const _confirmedAttendanceColumn = 'event_attendances.status';
  static const _confirmedAttendanceValue = 'confirmed';

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
        .eq(_confirmedAttendanceColumn, _confirmedAttendanceValue)
        .order('scheduled_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> fetchEventById(String eventId) {
    return _client
        .from(_eventsTable)
        .select(_eventColumns)
        .eq(_confirmedAttendanceColumn, _confirmedAttendanceValue)
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

  /// BLOCO 3: consulta `group_members` direto (mesma tabela, sem passar
  /// por `GroupRemoteDatasource`) filtrando já pelo `user_id` - só
  /// precisamos saber o papel do próprio usuário, não o de todo mundo.
  /// `maybeSingle()` retorna `null` sem lançar se o usuário não for
  /// membro (não deveria acontecer aqui, mas é mais seguro que `single()`).
  Future<String?> fetchOwnGroupRole(String groupId, String userId) async {
    final row = await _client
        .from('group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();
    return row?['role'] as String?;
  }

  /// BLOCO 3: `UPDATE` direto, sem RPC - a policy `events_update_admin`
  /// (ROLÊ-01) já restringe isso a admin/owner do grupo.
  Future<void> updateStatus(String eventId, String status) {
    return _client
        .from(_eventsTable)
        .update({'status': status})
        .eq('id', eventId);
  }

  /// BLOCO 3: mesma policy de [updateStatus] - reagendar é só outra
  /// coluna da mesma tabela, mesma permissão.
  Future<Map<String, dynamic>> updateScheduledAt(
    String eventId,
    DateTime scheduledAt,
  ) {
    return _client
        .from(_eventsTable)
        .update({'scheduled_at': scheduledAt.toIso8601String()})
        .eq('id', eventId)
        .eq(_confirmedAttendanceColumn, _confirmedAttendanceValue)
        .select(_eventColumns)
        .single();
  }
}
