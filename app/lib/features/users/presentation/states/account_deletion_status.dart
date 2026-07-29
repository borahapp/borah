/// Estado da exclusão de conta (RC-04C), mesmo padrão sealed-class usado
/// em toda feature do app (ex. `AuthStatus`, `UserProfileStatus`).
sealed class AccountDeletionStatus {
  const AccountDeletionStatus();
}

final class AccountDeletionInitial extends AccountDeletionStatus {
  const AccountDeletionInitial();
}

final class AccountDeletionInProgress extends AccountDeletionStatus {
  const AccountDeletionInProgress();
}

final class AccountDeletionSuccess extends AccountDeletionStatus {
  const AccountDeletionSuccess();
}

/// A reautenticação (confirmação de senha) falhou — distinto de
/// [AccountDeletionError] para que a tela mostre especificamente "senha
/// incorreta" sem reiniciar todo o fluxo de confirmação.
final class AccountDeletionReauthenticationError extends AccountDeletionStatus {
  const AccountDeletionReauthenticationError(this.message);

  final String message;
}

final class AccountDeletionError extends AccountDeletionStatus {
  const AccountDeletionError(this.message);

  final String message;
}
