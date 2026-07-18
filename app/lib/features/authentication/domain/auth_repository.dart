/// Dados mínimos de sessão — nenhuma entidade de perfil rica nesta etapa
/// (o perfil completo do usuário é escopo do DV-02).
typedef AuthUserData = ({String userId, String? email});

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

  AuthUserData? get currentUser;

  Stream<AuthUserData?> get onAuthStateChange;
}
