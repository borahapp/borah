/// Estado de autenticação (DV-01 SS9), modelado como sealed class.
///
/// Nomeado `AuthStatus` (nao `AuthState`) para evitar colisao com o tipo
/// `AuthState` do proprio pacote supabase_flutter, usado na camada de dados.
sealed class AuthStatus {
  const AuthStatus();
}

final class AuthInitial extends AuthStatus {
  const AuthInitial();
}

final class AuthLoading extends AuthStatus {
  const AuthLoading();
}

final class Authenticated extends AuthStatus {
  const Authenticated({required this.userId, required this.email});

  final String userId;
  final String? email;
}

final class Unauthenticated extends AuthStatus {
  const Unauthenticated();
}

final class AuthError extends AuthStatus {
  const AuthError(this.message);

  final String message;
}

final class EmailVerificationPending extends AuthStatus {
  const EmailVerificationPending(this.email);

  final String email;
}

final class PasswordResetSent extends AuthStatus {
  const PasswordResetSent(this.email);

  final String email;
}
