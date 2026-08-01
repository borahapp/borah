import 'event.dart';
import 'event_attendance.dart';

/// Agregado de domínio: rolê + presença de cada membro do grupo
/// (ROLÊ-03) - mesmo papel de `GroupDetails` para grupos. Entidade
/// própria (não um record), mesma decisão de `GroupDetails`.
class EventDetails {
  const EventDetails({required this.event, required this.attendances});

  final Event event;
  final List<EventAttendance> attendances;

  /// Contagem de confirmados, calculada em memória a partir das
  /// presenças já carregadas - nenhuma consulta extra ao banco (ROLÊ-03
  /// GAP 7: contagem só no detalhe, nunca na lista).
  int get confirmedCount => attendances.where((a) => a.isConfirmed).length;
}
