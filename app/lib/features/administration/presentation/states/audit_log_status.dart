import '../../../../core/models/paged_result.dart';
import '../../domain/audit_log_entry.dart';

/// Estado da consulta de auditoria (DV-08), somente leitura, sealed class.
sealed class AuditLogStatus {
  const AuditLogStatus();
}

final class AuditLogInitial extends AuditLogStatus {
  const AuditLogInitial();
}

final class AuditLogLoading extends AuditLogStatus {
  const AuditLogLoading();
}

final class AuditLogLoaded extends AuditLogStatus {
  const AuditLogLoaded(this.result);

  final PagedResult<AuditLogEntry> result;
}

final class AuditLogEmpty extends AuditLogStatus {
  const AuditLogEmpty();
}

final class AuditLogError extends AuditLogStatus {
  const AuditLogError(this.message);

  final String message;
}
