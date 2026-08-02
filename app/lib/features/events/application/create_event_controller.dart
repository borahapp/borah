import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_repository_impl.dart';
import '../domain/event_repository.dart';
import '../presentation/states/create_event_status.dart';

class CreateEventController extends Notifier<CreateEventStatus> {
  @override
  CreateEventStatus build() => const CreateEventInitial();

  EventRepository get _repository => ref.read(eventRepositoryProvider);

  /// Analytics (ROLÊ-03, não implementado - só documentado por decisão
  /// desta rodada): `AppAnalytics.trackEventCreated()` seria disparado
  /// aqui, só no `CreateEventSaveSuccess`, mesmo padrão de
  /// `trackReviewCreated`/`trackSignup` (RC-03C) - método ainda não
  /// existe em `AppAnalytics`, fica para quando o wiring de Analytics
  /// desta feature for decidido como rodada própria.
  Future<void> create({
    required String groupId,
    required String restaurantId,
    required DateTime scheduledAt,
  }) async {
    state = const CreateEventSaving();
    try {
      final event = await _repository.create(
        groupId: groupId,
        restaurantId: restaurantId,
        scheduledAt: scheduledAt,
      );
      state = CreateEventSaveSuccess(event);
    } on EventRepositoryException catch (e) {
      state = CreateEventError(e.message);
    } catch (_) {
      state = const CreateEventError('Não foi possível criar o rolê.');
    }
  }
}

final createEventControllerProvider =
    NotifierProvider<CreateEventController, CreateEventStatus>(
      CreateEventController.new,
    );
