import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/audit_log_entry.dart';
import '../domain/audit_log_repository.dart';
import 'audit_log_remote_datasource.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  AuditLogRepositoryImpl(this._datasource);

  final AuditLogRemoteDatasource _datasource;

  @override
  Future<void> log({
    required String actorId,
    required String action,
    required String entity,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) {
    return _guard(
      () => _datasource.insert({
        'actor_id': actorId,
        'action': action,
        'entity': entity,
        'entity_id': entityId,
        'metadata': metadata,
      }),
    );
  }

  @override
  Future<PagedResult<AuditLogEntry>> listRecent({
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listRecent(page: page, limit: limit);
      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      return PagedResult<AuditLogEntry>(
        items: pageRows.map(_mapRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  AuditLogEntry _mapRow(Map<String, dynamic> row) {
    return AuditLogEntry(
      id: row['id'] as String,
      actorId: row['actor_id'] as String,
      action: row['action'] as String,
      entity: row['entity'] as String,
      entityId: row['entity_id'] as String,
      metadata: row['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw AuditLogRepositoryException(e.message);
    }
  }
}

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuditLogRepositoryImpl(AuditLogRemoteDatasource(client));
});
