import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_repository_impl.dart';
import '../domain/event_attendance.dart';
import '../domain/event_details.dart';
import '../domain/event_repository.dart';
import '../presentation/states/event_detail_status.dart';

class EventDetailController extends Notifier<EventDetailStatus> {
  @override
  EventDetailStatus build() => const EventDetailInitial();

  EventRepository get _repository => ref.read(eventRepositoryProvider);

  /// Analytics (ROLÊ-03, ainda não implementado - só documentado por
  /// decisão desta rodada): abrir um rolê deveria disparar
  /// `AppAnalytics.trackEventOpened()`, mesmo padrão de
  /// `trackRestaurantViewed`/`trackFeedOpened` (RC-03C) - método ainda
  /// não existe em `AppAnalytics`, fica para quando o wiring de
  /// Analytics desta feature for decidido como rodada própria.
  Future<void> load(String eventId) async {
    state = const EventDetailLoading();
    try {
      final details = await _repository.getById(eventId);
      state = EventDetailLoaded(details);
    } on EventRepositoryException catch (e) {
      state = EventDetailError(e.message, null);
    } catch (_) {
      state = const EventDetailError('Não foi possível carregar o rolê.', null);
    }
  }

  /// Analytics (ROLÊ-03, não implementado - só documentado):
  /// `AppAnalytics.trackAttendanceConfirmed()` seria disparado aqui, só
  /// após o `await` ter sucesso (nunca no valor otimista, para não
  /// registrar uma confirmação que pode ainda ser revertida).
  Future<void> confirm(String attendanceId) =>
      _respond(attendanceId, status: 'confirmed');

  /// Analytics (ROLÊ-03, não implementado - só documentado): mesma
  /// observação de [confirm], com `AppAnalytics.trackAttendanceDeclined()`.
  Future<void> decline(String attendanceId) =>
      _respond(attendanceId, status: 'declined');

  /// Atualização otimista com rollback - mesmo padrão de
  /// `FavoriteToggleController.toggle`. [details] muda para o novo
  /// status antes da chamada ao repositório; se ela falhar, volta ao
  /// valor anterior e emite [EventDetailError] com a mensagem (ver
  /// documentação de `EventDetailError`).
  Future<void> _respond(String attendanceId, {required String status}) async {
    final current = state;
    if (current is! EventDetailLoaded) return;

    final previous = current.details;
    final optimistic = EventDetails(
      event: previous.event,
      attendances: [
        for (final attendance in previous.attendances)
          if (attendance.id == attendanceId)
            EventAttendance(
              id: attendance.id,
              userId: attendance.userId,
              status: status,
              fullName: attendance.fullName,
              avatarUrl: attendance.avatarUrl,
            )
          else
            attendance,
      ],
    );
    state = EventDetailLoaded(optimistic);

    try {
      if (status == 'confirmed') {
        await _repository.confirmAttendance(attendanceId);
      } else {
        await _repository.declineAttendance(attendanceId);
      }
    } on EventRepositoryException catch (e) {
      state = EventDetailError(e.message, previous);
    } catch (_) {
      state = EventDetailError(
        'Não foi possível registrar sua resposta.',
        previous,
      );
    }
  }
}

final eventDetailControllerProvider =
    NotifierProvider<EventDetailController, EventDetailStatus>(
      EventDetailController.new,
    );
