import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_controller.dart';
import '../data/event_repository_impl.dart';
import '../domain/event_attendance.dart';
import '../domain/event_details.dart';
import '../domain/event_repository.dart';
import '../presentation/states/event_detail_status.dart';
import 'events_list_controller.dart';

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
  ///
  /// [groupId] vem da própria rota (`/groups/:groupId/events/:eventId`,
  /// já disponível sem consulta nenhuma) - permite calcular
  /// `getById(eventId)` e `isGroupAdmin(groupId, ...)` em paralelo
  /// (`Future.wait`, BLOCO 3), já que um não depende do resultado do
  /// outro (diferente de group_id vir de dentro do próprio `Event`,
  /// o que forçaria as duas chamadas a serem sequenciais).
  Future<void> load(String eventId, String groupId) async {
    state = const EventDetailLoading();
    final userId = ref.read(currentUserIdProvider);
    try {
      final results = await Future.wait([
        _repository.getById(eventId),
        if (userId != null)
          _repository.isGroupAdmin(groupId: groupId, userId: userId),
      ]);
      final details = results[0] as EventDetails;
      final canManage = userId != null && results[1] as bool;
      state = EventDetailLoaded(details, canManage);
    } on EventRepositoryException catch (e) {
      state = EventDetailError(e.message, null, false);
    } catch (_) {
      state = const EventDetailError(
        'Não foi possível carregar o rolê.',
        null,
        false,
      );
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
    state = EventDetailLoaded(optimistic, current.canManage);

    try {
      if (status == 'confirmed') {
        await _repository.confirmAttendance(attendanceId);
      } else {
        await _repository.declineAttendance(attendanceId);
      }
    } on EventRepositoryException catch (e) {
      state = EventDetailError(e.message, previous, current.canManage);
    } catch (_) {
      state = EventDetailError(
        'Não foi possível registrar sua resposta.',
        previous,
        current.canManage,
      );
    }
  }

  /// Cancela o rolê (BLOCO 3, ação de admin/owner). Recarrega do
  /// servidor após o sucesso - mesma decisão de simplicidade do
  /// `GroupDetailController` (BLOCO 2): ação administrativa pontual,
  /// não um loop de 1 toque recorrente, então otimista não compensa.
  Future<void> cancel(String eventId) =>
      _mutate(() => _repository.cancel(eventId));

  /// Reagenda o rolê (BLOCO 3, ação de admin/owner).
  Future<void> reschedule(String eventId, DateTime scheduledAt) => _mutate(
    () => _repository.reschedule(eventId: eventId, scheduledAt: scheduledAt),
  );

  Future<void> _mutate(Future<void> Function() action) async {
    final current = state;
    final EventDetails? details;
    final bool canManage;
    if (current is EventDetailLoaded) {
      details = current.details;
      canManage = current.canManage;
    } else if (current is EventDetailError) {
      details = current.details;
      canManage = current.canManage;
    } else {
      return;
    }
    if (details == null) return;

    try {
      await action();
      // RC-02D: a listagem (`EventsListController`) não recarrega sozinha
      // ao voltar do Detalhe - `events_list_page.dart` só empurra essa
      // responsabilidade para o fluxo de criação (`_createEvent`), nunca
      // para abrir um rolê já existente (`onTap: () => context.push(...)`
      // sem `await`/reload). Sem isto, cancelar ou reagendar aqui deixa a
      // lista mostrando a data/status antigos até o app reiniciar - mesmo
      // padrão de bug já corrigido em Restaurantes/Criar rolê.
      ref
          .read(eventsListControllerProvider.notifier)
          .load(details.event.groupId);
      await load(details.event.id, details.event.groupId);
    } on EventRepositoryException catch (e) {
      state = EventDetailError(e.message, details, canManage);
    } catch (_) {
      state = EventDetailError(
        'Não foi possível concluir a ação.',
        details,
        canManage,
      );
    }
  }
}

final eventDetailControllerProvider =
    NotifierProvider<EventDetailController, EventDetailStatus>(
      EventDetailController.new,
    );
