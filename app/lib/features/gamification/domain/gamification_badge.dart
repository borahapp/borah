/// Entidade de badge (DV-10 §9). Nomeada `GamificationBadge` (não
/// `Badge`) para evitar colisão com o widget `Badge` do Material 3 -
/// mesma lição do `AppNotification` sobre `Notification`.
class GamificationBadge {
  const GamificationBadge({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
}

/// Um badge já conquistado por um usuário, com a data de conquista.
class EarnedBadge {
  const EarnedBadge({required this.badge, required this.earnedAt});

  final GamificationBadge badge;
  final DateTime earnedAt;
}
