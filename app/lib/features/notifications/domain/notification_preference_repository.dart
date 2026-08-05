/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class NotificationPreferenceRepositoryException implements Exception {
  const NotificationPreferenceRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Preferências (DV-09 decisão 7, estendido na
/// RC-03 Sprint 0 - F48). `category` passou a ser parâmetro explícito:
/// 'social' e 'groups' têm eventos reais implementados hoje (DV-09,
/// `20260801130000_add_group_event_notifications.sql`); as demais
/// categorias do CHECK constraint continuam existindo apenas como
/// estrutura de banco, sem UI própria ainda.
abstract interface class NotificationPreferenceRepository {
  Future<bool> isInAppEnabled(String userId, String category);

  Future<void> setInAppEnabled(String userId, String category, bool enabled);
}
