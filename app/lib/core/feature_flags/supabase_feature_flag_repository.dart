import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, SupabaseClient;

import 'feature_flag.dart';
import 'feature_flag_repository.dart';

/// Única classe do projeto que consulta a tabela `feature_flags`
/// diretamente (RC-03D) — mesmo papel que `PostHogAnalyticsService`
/// desempenha para o PostHog (RC-03C): a única fronteira com o SDK/banco.
class SupabaseFeatureFlagRepository implements FeatureFlagRepository {
  SupabaseFeatureFlagRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'feature_flags';

  @override
  Future<List<FeatureFlag>> fetchAll() async {
    try {
      final rows = await _client.from(_table).select();
      return rows.map(FeatureFlag.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw FeatureFlagRepositoryException(e.message);
    }
  }
}
