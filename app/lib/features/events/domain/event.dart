/// Entidade de Rolê (ROLÊ-02) - só os campos necessários nesta sprint
/// (criação). `organizerId`/`createdAt`/`updatedAt` existem na tabela
/// (ROLÊ-01) mas nenhuma tela usa ainda - ficam para quando a tela de
/// Detalhe do Rolê existir.
class Event {
  const Event({
    required this.id,
    required this.groupId,
    required this.restaurantId,
    required this.scheduledAt,
    required this.status,
  });

  final String id;
  final String groupId;
  final String restaurantId;
  final DateTime scheduledAt;

  /// Valor real do banco (`scheduled`/`completed`/`cancelled` - ROLÊ-01).
  final String status;
}
