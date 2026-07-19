/// Estado de seguir/deixar de seguir um usuário específico (DV-07) -
/// mesma forma do `FavoriteToggleStatus` (DV-06), sem atualização
/// otimista (não solicitada para este módulo).
sealed class FollowStatus {
  const FollowStatus();
}

final class FollowInitial extends FollowStatus {
  const FollowInitial();
}

final class FollowLoading extends FollowStatus {
  const FollowLoading();
}

final class FollowLoaded extends FollowStatus {
  const FollowLoaded(this.isFollowing);

  final bool isFollowing;
}

final class FollowError extends FollowStatus {
  const FollowError(this.message);

  final String message;
}
