import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula a chamada RPC de auto-exclusão de conta (RC-04C).
///
/// `delete_own_account()` é uma função Postgres `SECURITY DEFINER`
/// (migration `20260725150000_create_delete_own_account_function.sql`)
/// — a única forma de apagar a linha de `auth.users` do próprio usuário
/// sem a `SERVICE_ROLE_KEY` (nunca presente no app, RC-04A) e sem Edge
/// Functions (infraestrutura que este projeto não tem, DV-08). A função
/// só pode afetar `auth.uid()` — nenhum parâmetro é aceito.
class AccountDeletionRemoteDatasource {
  AccountDeletionRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<void> deleteOwnAccount() {
    return _client.rpc('delete_own_account');
  }
}
