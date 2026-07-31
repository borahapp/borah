import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula a chamada RPC de criacao de grupo (GROUP-02A).
///
/// `create_group()` e uma funcao Postgres `SECURITY DEFINER`
/// (migration `20260731090000_create_groups_and_group_members.sql`) -
/// insere o grupo e o proprio chamador como `owner` em `group_members`
/// na mesma transacao (INSERT direto em `groups`/`group_members` e
/// bloqueado por RLS para o cliente). `auth.uid()` e resolvido pela
/// propria funcao no Postgres - nenhum id de usuario e passado como
/// parametro. Nomes dos parametros (`p_name`/`p_description`/
/// `p_photo_url`) precisam bater exatamente com a assinatura da funcao.
class GroupRemoteDatasource {
  GroupRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _groupsTable = 'groups';
  static const _membersTable = 'group_members';
  static const _profilesTable = 'profiles';

  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
    String? photoUrl,
  }) async {
    final result = await _client.rpc(
      'create_group',
      params: {
        'p_name': name,
        'p_description': description,
        'p_photo_url': photoUrl,
      },
    );
    return result as Map<String, dynamic>;
  }

  /// GROUP-02B.0: `SELECT` direto, sem RPC - a policy `groups_select_members`
  /// (GROUP-01) já restringe as linhas retornadas aos grupos do usuário
  /// autenticado, então nenhum filtro adicional é necessário aqui.
  Future<List<Map<String, dynamic>>> listMine() async {
    final rows = await _client
        .from(_groupsTable)
        .select('id,name,description,photo_url,invite_code')
        .order('last_activity_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// GROUP-02B.1: 3 consultas, sem embed, sem RPC - mesmo padrão de
  /// `FollowerRemoteDatasource` (`group_members.user_id`/`profiles.id`
  /// referenciam `auth.users` independentemente; não há FK direta entre
  /// `group_members` e `profiles` que o PostgREST possa usar num embed).
  Future<Map<String, dynamic>> fetchGroupById(String id) {
    return _client
        .from(_groupsTable)
        .select('id,name,description,photo_url,invite_code')
        .eq('id', id)
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchMembers(String groupId) async {
    final rows = await _client
        .from(_membersTable)
        .select('user_id,role')
        .eq('group_id', groupId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Mesmo método/assinatura de `FollowerRemoteDatasource.fetchProfilesByIds`.
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
}
