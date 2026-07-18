import '../../domain/user_profile.dart';

/// Estado do perfil (DV-02 §10), modelado como sealed class.
///
/// Prefixo `Profile*` (não `Loading`/`Error` genéricos) para evitar
/// colisão com os estados de outros módulos, como o `AuthStatus` do DV-01.
sealed class UserProfileStatus {
  const UserProfileStatus();
}

final class ProfileInitial extends UserProfileStatus {
  const ProfileInitial();
}

final class ProfileLoading extends UserProfileStatus {
  const ProfileLoading();
}

final class ProfileLoaded extends UserProfileStatus {
  const ProfileLoaded(this.profile);

  final UserProfile profile;
}

final class ProfileUpdating extends UserProfileStatus {
  const ProfileUpdating(this.profile);

  final UserProfile profile;
}

final class ProfileUpdateSuccess extends UserProfileStatus {
  const ProfileUpdateSuccess(this.profile);

  final UserProfile profile;
}

final class ProfileError extends UserProfileStatus {
  const ProfileError(this.message);

  final String message;
}
