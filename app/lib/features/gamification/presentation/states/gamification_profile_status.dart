import '../../domain/gamification_badge.dart';
import '../../domain/groups_activity_summary.dart';
import '../../domain/user_progress.dart';

/// Estado do Perfil de Gamificação (DV-10 §10, adaptado), sealed class.
sealed class GamificationProfileStatus {
  const GamificationProfileStatus();
}

final class GamificationProfileInitial extends GamificationProfileStatus {
  const GamificationProfileInitial();
}

final class GamificationProfileLoading extends GamificationProfileStatus {
  const GamificationProfileLoading();
}

final class GamificationProfileLoaded extends GamificationProfileStatus {
  const GamificationProfileLoaded({
    required this.progress,
    required this.allBadges,
    required this.earnedBadgeIds,
    required this.groupsActivity,
  });

  final UserProgress progress;
  final List<GamificationBadge> allBadges;
  final Set<String> earnedBadgeIds;

  /// FASE B, Entrega 4: soma de rolês/avaliações coletivas entre todos
  /// os grupos do usuário - alimenta a seção "XP de rolês".
  final GroupsActivitySummary groupsActivity;
}

final class GamificationProfileError extends GamificationProfileStatus {
  const GamificationProfileError(this.message);

  final String message;
}
