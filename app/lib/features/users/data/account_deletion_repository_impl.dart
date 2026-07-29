import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/errors/supabase_error_translator.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/account_deletion_repository.dart';
import 'account_deletion_remote_datasource.dart';

class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  AccountDeletionRepositoryImpl(this._datasource);

  final AccountDeletionRemoteDatasource _datasource;

  @override
  Future<void> deleteOwnAccount() async {
    try {
      await _datasource.deleteOwnAccount();
    } on PostgrestException catch (e) {
      // RC-04E: tela de ação irreversível - mensagem sempre traduzida.
      throw AccountDeletionRepositoryException(
        SupabaseErrorTranslator.translatePostgrestError(e),
      );
    }
  }
}

final accountDeletionRepositoryProvider = Provider<AccountDeletionRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return AccountDeletionRepositoryImpl(AccountDeletionRemoteDatasource(client));
});
