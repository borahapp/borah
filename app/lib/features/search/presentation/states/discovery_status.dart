import '../../../users/domain/user_profile.dart';

/// Estado de "Você pode conhecer" (FASE SOCIAL 2), sealed class - mesmo
/// padrão do resto do app.
sealed class DiscoveryStatus {
  const DiscoveryStatus();
}

final class DiscoveryInitial extends DiscoveryStatus {
  const DiscoveryInitial();
}

final class DiscoveryLoading extends DiscoveryStatus {
  const DiscoveryLoading();
}

final class DiscoveryLoaded extends DiscoveryStatus {
  const DiscoveryLoaded(this.people, {required this.hasMore});

  final List<UserProfile> people;
  final bool hasMore;
}

/// Nenhuma sugestão disponível (sem grupos em comum, sem quem seguir em
/// comum) - distinto de erro, não é um estado de falha.
final class DiscoveryEmpty extends DiscoveryStatus {
  const DiscoveryEmpty();
}

final class DiscoveryError extends DiscoveryStatus {
  const DiscoveryError(this.message);

  final String message;
}
