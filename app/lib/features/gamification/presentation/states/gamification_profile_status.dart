import '../../domain/gamification_badge.dart';
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
  });

  final UserProgress progress;
  final List<GamificationBadge> allBadges;
  final Set<String> earnedBadgeIds;
}

final class GamificationProfileError extends GamificationProfileStatus {
  const GamificationProfileError(this.message);

  final String message;
}
