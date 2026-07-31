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
}
