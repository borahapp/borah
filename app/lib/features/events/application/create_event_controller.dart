import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_repository_impl.dart';
import '../domain/event_repository.dart';
import '../presentation/states/create_event_status.dart';

class CreateEventController extends Notifier<CreateEventStatus> {
  @override
  CreateEventStatus build() => const CreateEventInitial();

  EventRepository get _repository => ref.read(eventRepositoryProvider);

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
