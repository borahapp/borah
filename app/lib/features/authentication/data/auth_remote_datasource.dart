import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart' show AuthRepositoryException;

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

  /// AUTH-01: pontos de extensão para os provedores sociais/anônimo — cada
  /// stub lança para deixar claro que a conexão real com o SDK de cada
  /// provedor (Google/Apple/Facebook) ainda não foi implementada; a sprint
  /// que conectar cada um substitui só o corpo do método correspondente
  /// (ex.: `_client.auth.signInWithIdToken(...)`), sem tocar nas camadas
  /// acima (`AuthRepositoryImpl`, `AuthController`).
  Future<void> signInWithGoogle() async {
    throw const AuthRepositoryException(
      'Login com Google ainda não está disponível.',
    );
  }

  Future<void> signInWithApple() async {
    throw const AuthRepositoryException(
      'Login com Apple ainda não está disponível.',
    );
  }

  Future<void> signInWithFacebook() async {
    throw const AuthRepositoryException(
      'Login com Facebook ainda não está disponível.',
    );
  }

  /// Ao contrário dos demais provedores, não depende de um SDK nativo
  /// externo (o próprio Supabase resolve `signInAnonymously()` sem
  /// credencial) — mesmo assim, permanece como stub nesta sprint (AUTH-01
  /// é só infraestrutura, sem nenhum login efetivamente habilitado).
  Future<void> signInAnonymously() async {
    throw const AuthRepositoryException(
      'Login anônimo ainda não está disponível.',
    );
  }

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
