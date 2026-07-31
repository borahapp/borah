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
        .from('groups')
        .select('id,name,description,photo_url,invite_code')
        .order('last_activity_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
