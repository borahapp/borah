import '../../../core/models/paged_result.dart';
import 'audit_log_entry.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class AuditLogRepositoryException implements Exception {
  const AuditLogRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Auditoria (DV-08). Tabela append-only - não há
/// `update`/`delete` no contrato, mesmo para quem chama (decisão do DV-08).
/// Modo "melhor esforço": `log` é chamado depois da ação administrativa
/// já ter sido executada, sem transação entre as duas escritas.
abstract interface class AuditLogRepository {
  Future<void> log({
    required String actorId,
    required String action,
    required String entity,
    required String entityId,
    Map<String, dynamic>? metadata,
  });

  Future<PagedResult<AuditLogEntry>> listRecent({
    required int page,
    required int limit,
  });
}
