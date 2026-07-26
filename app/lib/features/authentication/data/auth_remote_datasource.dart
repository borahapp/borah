import 'package:supabase_flutter/supabase_flutter.dart';

/// Deep link de callback da recuperação de senha (RC-04E). O
/// `supabase_flutter` já observa automaticamente qualquer URI recebida
/// pelo SO que contenha `access_token`/`code`/`error` e troca por uma
/// sessão via `getSessionFromUrl` - não é necessário nenhum parsing manual
/// aqui, só registrar o mesmo esquema na configuração nativa
/// (`AndroidManifest.xml`/`Info.plist`) e no Supabase Dashboard
/// (Authentication → URL Configuration → Redirect URLs). Ver
/// `RC-04E_CLOSED_BETA.md` para o passo a passo de configuração.
const String passwordRecoveryRedirectUrl = 'borah://password-recovery';

/// Encapsula as chamadas ao Supabase Auth (DV-01 SS11).
class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> requestPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: passwordRecoveryRedirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> resendVerificationEmail(String email) {
    return _client.auth.resend(email: email, type: OtpType.signup);
  }

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
