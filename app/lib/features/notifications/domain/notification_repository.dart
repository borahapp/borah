import '../../../core/models/paged_result.dart';
import 'app_notification.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class NotificationRepositoryException implements Exception {
  const NotificationRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Notificações (DV-09). Não há método de criação
/// aqui - toda notificação é produzida exclusivamente pelos triggers do
/// banco (decisão 4 do DV-09); o cliente só lê e marca como lida.
abstract interface class NotificationRepository {
  Future<PagedResult<AppNotification>> listForUser(
    String userId, {
    required int page,
    required int limit,
  });

  Future<void> markAsRead(String id);

  /// Atualiza apenas as notificações ainda não lidas (decisão 8 do DV-09).
  Future<void> markAllAsRead(String userId);

  /// RC-03 F25 - atividade do grupo (novo rolê, resposta de presença,
  /// novo membro), deduplicada entre destinatários do mesmo evento -
  /// reaproveita `notifications` como fonte, nunca uma tabela paralela
  /// (`RC03_FEATURE_GAP.md §6`, item 3). Os campos `id`/`userId`/`isRead`
  /// de cada item não têm significado individual aqui (vêm de um
  /// destinatário arbitrário do fan-out) - a UI consumidora nunca deve
  /// usá-los para marcar como lida ou navegar por eles.
  Future<PagedResult<AppNotification>> listGroupActivity(
    String groupId, {
    required int page,
    required int limit,
  });
}
