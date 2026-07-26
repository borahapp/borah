/// Dados mínimos de sessão — nenhuma entidade de perfil rica nesta etapa
/// (o perfil completo do usuário é escopo do DV-02).
typedef AuthUserData = ({String userId, String? email});

/// Eventos de sessão relevantes para a aplicação, independentes do
/// `AuthChangeEvent` do Supabase (RC-04E). `passwordRecovery` é o único
/// caso que precisa de tratamento distinto de `signedIn`/`signedOut`: o
/// link de recuperação de senha estabelece uma sessão temporária que não
/// deve ser tratada como um login normal, até o usuário definir uma nova
/// senha (`AuthRepository.updatePassword`).
enum AuthSessionEvent { signedIn, signedOut, passwordRecovery }

/// Atualização emitida por [AuthRepository.onAuthStateChange] - par
/// evento + dados do usuário (nulo quando `event == signedOut`).
typedef AuthSessionUpdate = ({AuthSessionEvent event, AuthUserData? user});

/// Erro de autenticação traduzido pela camada de dados — mantém o domínio
/// e a aplicação sem depender do tipo de exceção do Supabase.
class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio, independente de Flutter e Supabase (AR-02).
abstract interface class AuthRepository {
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> requestPasswordReset(String email);

  /// Define uma nova senha durante a recuperação de senha (RC-04E) -
  /// só é válida enquanto existir uma sessão de recuperação ativa
  /// (`AuthSessionEvent.passwordRecovery`), estabelecida automaticamente
  /// pelo `supabase_flutter` ao abrir o deep link de recuperação.
  Future<void> updatePassword(String newPassword);

  /// Reenvia o e-mail de confirmação de cadastro (RC-02, Quick Win —
  /// fecha o dead-end de conta reportado na RC-01).
  Future<void> resendVerificationEmail(String email);

  AuthUserData? get currentUser;

  Stream<AuthSessionUpdate> get onAuthStateChange;
}
