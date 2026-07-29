/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class NotificationPreferenceRepositoryException implements Exception {
  const NotificationPreferenceRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Preferências (DV-09 decisão 7). Só a categoria
/// 'social' tem um evento real implementado - por isso o contrato não
/// parametriza por categoria; as demais categorias existem apenas como
/// estrutura de banco (decisão 5).
abstract interface class NotificationPreferenceRepository {
  Future<bool> isInAppEnabled(String userId);

  Future<void> setInAppEnabled(String userId, bool enabled);
}
