import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, SupabaseClient;

import 'feedback_model.dart';
import 'feedback_repository.dart';

/// Única classe do projeto que consulta a tabela `feedback` diretamente
/// (RC-03E) — mesmo papel que `SupabaseFeatureFlagRepository` desempenha
/// para `feature_flags` (RC-03D): a única fronteira com o Supabase.
class SupabaseFeedbackRepository implements FeedbackRepository {
  SupabaseFeedbackRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'feedback';

  @override
  Future<FeedbackModel> submit({
    required String userId,
    required String message,
    String? screenContext,
    String? appVersion,
    String? environment,
  }) async {
    try {
      final row = await _client
          .from(_table)
          .insert({
            'user_id': userId,
            'message': message,
            'screen_context': screenContext,
            'app_version': appVersion,
            'environment': environment,
          })
          .select()
          .single();
      return FeedbackModel.fromMap(row);
    } on PostgrestException catch (e) {
      throw FeedbackRepositoryException(e.message);
    }
  }
}
