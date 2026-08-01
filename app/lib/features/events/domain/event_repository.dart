import 'event.dart';
import 'event_details.dart';

/// Erro traduzido pela camada de dados - mesmo padrão de
/// `GroupRepositoryException`/`RestaurantRepositoryException` (nenhuma
/// classe base comum existe no projeto; cada feature define a sua).
class EventRepositoryException implements Exception {
  const EventRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio, independente de Flutter e Supabase (AR-02).
/// `create` (ROLÊ-02); `listByGroup`/`getById`/`confirmAttendance`/
/// `declineAttendance` (ROLÊ-03) - fotos, avaliação, edição e
/// cancelamento ficam para as próximas etapas do módulo Events.
abstract interface class EventRepository {
  Future<Event> create({
    required String groupId,
    required String restaurantId,
    required DateTime scheduledAt,
  });

  /// Rolês do grupo, ordenados por data agendada mais próxima primeiro
  /// (ROLÊ-03). Sem distinção visual entre "próximos" e "realizados"
  /// nesta sprint - registrado como melhoria futura (relatório final).
  Future<List<Event>> listByGroup(String groupId);

  /// Rolê + presença de cada membro do grupo (ROLÊ-03). Lança
  /// [EventRepositoryException] se o rolê não existir ou o usuário não
  /// for membro do grupo (a RLS de `events`/`event_attendances` filtra
  /// antes disso).
  Future<EventDetails> getById(String eventId);

  /// Confirma a própria presença. [attendanceId] é o `id` da linha de
  /// `event_attendances` do usuário autenticado - a RLS
  /// (`event_attendances_update_own`) garante que só a própria linha
  /// pode ser alterada, então nenhum outro parâmetro é necessário.
  Future<void> confirmAttendance(String attendanceId);

  /// Recusa a própria presença. Mesma garantia de [confirmAttendance].
  Future<void> declineAttendance(String attendanceId);
}
