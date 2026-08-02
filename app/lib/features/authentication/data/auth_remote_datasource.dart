import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/environment/app_environment.dart';
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

  /// AUTH-02: `GoogleSignIn.instance.initialize()` só pode ser chamado uma
  /// vez por execução do app (documentado no changelog 7.1.1 do pacote) -
  /// como não há nenhum ponto de bootstrap chamando isso ainda (sem UI de
  /// login social nesta sprint), a inicialização é feita de forma tardia
  /// e única aqui, guardada por este Future em cache.
  Future<void>? _googleSignInInitialization;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??= GoogleSignIn.instance.initialize(
      clientId: AppEnvironment.googleIosClientId.isEmpty
          ? null
          : AppEnvironment.googleIosClientId,
      serverClientId: AppEnvironment.googleServerClientId.isEmpty
          ? null
          : AppEnvironment.googleServerClientId,
    );
  }

  /// AUTH-02: fluxo nativo (`signInWithIdToken`) - o SDK do Google só
  /// resolve a autenticação local; quem efetivamente cria/reconhece a
  /// sessão do usuário é o Supabase, a partir do `idToken` validado.
  /// Falha fechada: sem `GOOGLE_SERVER_CLIENT_ID` configurado, recusa
  /// antes de sequer inicializar o SDK (mesmo espírito do
  /// `TURNSTILE_SECRET_KEY` ausente no backend do site).
  Future<void> signInWithGoogle() async {
    if (AppEnvironment.googleServerClientId.isEmpty) {
      throw const AuthRepositoryException(
        'Login com Google ainda não está configurado.',
      );
    }
    try {
      await _ensureGoogleSignInInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthRepositoryException(
          'Não foi possível obter as credenciais do Google.',
        );
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthRepositoryException('Login com Google cancelado.');
      }
      throw AuthRepositoryException(
        'Não foi possível entrar com Google. ${e.description ?? ''}'.trim(),
      );
    }
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
