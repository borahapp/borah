import 'event.dart';

/// Erro traduzido pela camada de dados - mesmo padrão de
/// `GroupRepositoryException`/`RestaurantRepositoryException` (nenhuma
/// classe base comum existe no projeto; cada feature define a sua).
class EventRepositoryException implements Exception {
  const EventRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio, independente de Flutter e Supabase (AR-02).
/// Apenas `create` nesta sprint (ROLÊ-02) - confirmação de presença,
/// fotos, avaliação, edição, cancelamento, lista e detalhe ficam para
/// as próximas etapas do módulo Events.
abstract interface class EventRepository {
  Future<Event> create({
    required String groupId,
    required String restaurantId,
    required DateTime scheduledAt,
  });
}
