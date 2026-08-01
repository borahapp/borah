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
/// `declineAttendance` (ROLÊ-03); `isGroupAdmin`/`cancel`/`reschedule`
/// (BLOCO 3) - fotos e avaliação ficam para as próximas etapas.
abstract interface class EventRepository {
  Future<Event> create({
    required String groupId,
    required String restaurantId,
    required DateTime scheduledAt,
  });

  /// Rolês do grupo, ordenados por data agendada mais próxima primeiro.
  /// A separação visual "Próximos"/"Realizados" (BLOCO 3) usa
  /// `Event.isUpcoming` sobre esta mesma lista - sem parâmetro nem
  /// consulta adicional aqui.
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

  /// Se o usuário [userId] é admin/owner do grupo [groupId] (BLOCO 3) -
  /// usado só para decidir se a UI mostra cancelar/reagendar. Consulta
  /// `group_members` diretamente, sem depender de `GroupRepository`
  /// (mesma decisão já tomada para o embed de `restaurants` em
  /// `Event` - cada feature acessa as tabelas compartilhadas de que
  /// precisa, sem acoplar a classes de outra feature).
  Future<bool> isGroupAdmin({required String groupId, required String userId});

  /// Cancela o rolê (BLOCO 3, ação de admin/owner do grupo). Ação
  /// definitiva - não há "reabrir" nesta sprint.
  Future<void> cancel(String eventId);

  /// Reagenda o rolê para uma nova data/hora (BLOCO 3, ação de
  /// admin/owner). Só `scheduled_at` - trocar o restaurante fica fora
  /// do escopo (mudaria o contexto de quem já confirmou presença).
  Future<Event> reschedule({required String eventId, required DateTime scheduledAt});
}
