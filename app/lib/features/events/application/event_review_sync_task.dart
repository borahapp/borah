import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lazy_sync/lazy_sync_task.dart';
import '../data/event_repository_impl.dart';

/// FASE C.4 - implementação de [LazySyncTask] para a notificação
/// "Avaliação liberada". Fina de propósito: toda a regra mora na RPC
/// (`notify_events_ready_for_review`, idempotente por natureza); esta
/// classe só existe para que `core/lazy_sync/` (que nunca importa
/// nenhuma feature) consiga acioná-la sem conhecer `EventRepository`.
class EventReviewSyncTask implements LazySyncTask {
  EventReviewSyncTask(this._ref);

  final Ref _ref;

  @override
  Future<void> run() {
    return _ref.read(eventRepositoryProvider).notifyReadyForReview();
  }
}
