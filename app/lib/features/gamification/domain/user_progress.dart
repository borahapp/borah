/// Entidade de progresso de gamificação (DV-10 §9). Sem linha até o
/// primeiro evento do usuário no banco - `GamificationRepository.getProgress`
/// retorna um valor zerado quando não há registro, evitando null-handling
/// na apresentação.
class UserProgress {
  const UserProgress({
    required this.userId,
    required this.xp,
    required this.points,
    required this.level,
    required this.updatedAt,
  });

  final String userId;
  final int xp;
  final int points;
  final int level;
  final DateTime updatedAt;

  /// Limiares oficiais da v1.0 (decisão do DV-10) - usado para a barra de
  /// progresso até o próximo nível.
  static const levelThresholds = {1: 0, 2: 200, 3: 500, 4: 900};
}
