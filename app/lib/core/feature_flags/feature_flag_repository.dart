import 'feature_flag.dart';

/// Erro traduzido pela camada de dados (mesmo padrão já usado em todo o
/// app, ex. `FavoriteRepositoryException`) — nenhuma camada acima
/// conhece exceções do Supabase.
class FeatureFlagRepositoryException implements Exception {
  const FeatureFlagRepositoryException(this.message);

  final String message;
}

/// Contrato de acesso a dados das Feature Flags (RC-03D). Nenhuma
/// feature deve acessar a tabela `feature_flags` diretamente — toda
/// comunicação passa por esta interface (ou, mais acima, por
/// [FeatureFlagService]/`AppFeatureFlags`).
abstract interface class FeatureFlagRepository {
  /// Busca todas as flags cadastradas. Pode lançar
  /// [FeatureFlagRepositoryException] — quem chama (sempre
  /// [FeatureFlagService], nunca uma feature diretamente) é responsável
  /// por decidir o que fazer com a falha (ver RC-03D §Erros).
  Future<List<FeatureFlag>> fetchAll();
}
