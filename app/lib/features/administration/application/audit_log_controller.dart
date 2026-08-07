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
  int _requestId = 0;
  static const _limit = 20;

  Future<void> load() {
    _page = 1;
    return _run(const AuditLogLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! AuditLogLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `FeedController._run`): só a resposta cujo `requestId` ainda bate com
  /// `_requestId` no momento em que o fetch resolve pode escrever em
  /// `state` - evita que um `loadNextPage` disparado durante um `load`
  /// produza um resultado final inconsistente, qualquer que seja a ordem
  /// das respostas.
  Future<void> _run(
    AuditLogStatus loadingState, {
    List<AuditLogEntry> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listRecent(page: _page, limit: _limit);
      if (requestId != _requestId) return;
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
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      if (previousItems.isNotEmpty) return;
      state = AuditLogError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) return;
      state = const AuditLogError('Não foi possível carregar a auditoria.');
    }
  }
}

final auditLogControllerProvider =
    NotifierProvider<AuditLogController, AuditLogStatus>(
      AuditLogController.new,
    );
