import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_repository_impl.dart';
import '../domain/event_repository.dart';
import '../presentation/states/events_list_status.dart';

class EventsListController extends Notifier<EventsListStatus> {
  @override
  EventsListStatus build() => const EventsListInitial();

  EventRepository get _repository => ref.read(eventRepositoryProvider);

  Future<void> load(String groupId) async {
    state = const EventsListLoading();
    try {
      final events = await _repository.listByGroup(groupId);
      state = events.isEmpty
          ? const EventsListEmpty()
          : EventsListLoaded(events);
    } on EventRepositoryException catch (e) {
      state = EventsListError(e.message);
    } catch (_) {
      state = const EventsListError('Não foi possível carregar os rolês.');
    }
  }
}

final eventsListControllerProvider =
    NotifierProvider<EventsListController, EventsListStatus>(
      EventsListController.new,
    );
