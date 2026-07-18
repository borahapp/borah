/// Dados mínimos de sessão — nenhuma entidade de perfil rica nesta etapa
/// (o perfil completo do usuário é escopo do DV-02).
typedef AuthUserData = ({String userId, String? email});

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

  AuthUserData? get currentUser;

  Stream<AuthUserData?> get onAuthStateChange;
}
