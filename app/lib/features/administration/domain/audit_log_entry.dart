/// Entidade de registro de auditoria (DV-08 §10 `audit_logs`).
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.action,
    required this.entity,
    required this.entityId,
    this.metadata,
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final String action;
  final String entity;
  final String entityId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
}
