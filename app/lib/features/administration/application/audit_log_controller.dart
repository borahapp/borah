import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../data/audit_log_repository_impl.dart';
import '../domain/audit_log_entry.dart';
import '../domain/audit_log_repository.dart';
import '../presentation/states/audit_log_status.dart';

/// Consulta de auditoria (DV-08 §7), somente leitura - a tabela é
/// append-only, este controller nunca escreve nela.
class AuditLogController extends Notifier<AuditLogStatus> {
  @override
  AuditLogStatus build() => const AuditLogInitial();

  AuditLogRepository get _repository => ref.read(auditLogRepositoryProvider);

  int _page = 1;
  static const _limit = 20;

  Future<void> load() {
    _page = 1;
    return _run(const AuditLogLoading());
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! AuditLogLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(current, previousItems: current.result.items);
  }

  Future<void> _run(
    AuditLogStatus loadingState, {
    List<AuditLogEntry> previousItems = const [],
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listRecent(page: _page, limit: _limit);
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const AuditLogEmpty()
          : AuditLogLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on AuditLogRepositoryException catch (e) {
      state = AuditLogError(e.message);
    } catch (_) {
      state = const AuditLogError('Não foi possível carregar a auditoria.');
    }
  }
}

final auditLogControllerProvider =
    NotifierProvider<AuditLogController, AuditLogStatus>(
      AuditLogController.new,
    );
