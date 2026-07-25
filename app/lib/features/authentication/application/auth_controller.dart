import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/app_analytics.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../presentation/states/auth_status.dart';

final _authStateChangesProvider = StreamProvider<AuthUserData?>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// Camada de aplicacao: fluxo simples AuthRepository -> AuthController,
/// sem use cases intermediarios para operacoes de chamada unica.
class AuthController extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    ref.listen(_authStateChangesProvider, (_, next) {
      next.whenData((userData) {
        state = userData == null
            ? const Unauthenticated()
            : Authenticated(userId: userData.userId, email: userData.email);
      });
    });
    return const AuthInitial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Usado exclusivamente pela Splash Screen para restaurar a sessao.
  Future<void> restoreSession() async {
    state = const AuthLoading();
    final current = _repository.currentUser;
    // RC-03C: identifica o usuário para o Analytics mesmo numa
    // restauração de sessão (não só num login novo) - é o caminho mais
    // comum de abertura do app, e sem isso a maioria dos eventos
    // ficaria sem `userId`. Fire-and-forget: Analytics nunca deve
    // atrasar/bloquear o fluxo de autenticação.
    if (current != null) unawaited(AppAnalytics.identify(current.userId));
    state = current == null
        ? const Unauthenticated()
        : Authenticated(userId: current.userId, email: current.email);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      await _repository.signUp(name: name, email: email, password: password);
      // Quando a confirmação de e-mail está desabilitada no projeto
      // Supabase, signUp() já retorna com uma sessão ativa - definir
      // EmailVerificationPending incondicionalmente aqui entraria em
      // condição de corrida com o listener de onAuthStateChange (que
      // também reage à sessão recém-criada definindo Authenticated),
      // já que ambos escrevem em `state` de forma assíncrona e
      // independente. Consultar `currentUser` logo após o await (mesma
      // técnica já usada em signIn()/restoreSession()) resolve o estado
      // real de forma determinística, sem depender de qual dos dois
      // caminhos assíncronos "vence".
      final current = _repository.currentUser;
      if (current != null) unawaited(AppAnalytics.identify(current.userId));
      unawaited(AppAnalytics.trackSignup());
      state = current == null
          ? EmailVerificationPending(email)
          : Authenticated(userId: current.userId, email: current.email);
    } on AuthRepositoryException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError('Não foi possível concluir o cadastro.');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      await _repository.signIn(email: email, password: password);
      final current = _repository.currentUser;
      if (current != null) unawaited(AppAnalytics.identify(current.userId));
      unawaited(AppAnalytics.trackLoginSuccess());
      state = current == null
          ? const Unauthenticated()
          : Authenticated(userId: current.userId, email: current.email);
    } on AuthRepositoryException catch (e) {
      unawaited(AppAnalytics.trackLoginFailed(reason: e.message));
      state = AuthError(e.message);
    } catch (_) {
      unawaited(AppAnalytics.trackLoginFailed());
      state = const AuthError(
        'Não foi possível entrar. Verifique suas credenciais.',
      );
    }
  }

  /// Ao contrário dos demais métodos, não expressa "tentando"/"falhou"
  /// através do `AuthStatus` global: o `redirect` do router (AR-02) trata
  /// qualquer status que não seja `Authenticated` como motivo para sair de
  /// uma rota protegida (ex. `/settings`), então um `AuthLoading`/`AuthError`
  /// aqui navegaria embora da tela antes (ou apesar) do resultado real da
  /// chamada. O chamador (`SettingsPage`) trata loading/erro localmente.
  Future<void> signOut() async {
    try {
      await _repository.signOut();
      // Rastreia o logout antes de resetar - assim o próprio evento
      // ainda carrega o `userId` de quem estava saindo.
      unawaited(AppAnalytics.trackLogout());
      unawaited(AppAnalytics.reset());
      state = const Unauthenticated();
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Não foi possível encerrar a sessão.',
      );
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = const AuthLoading();
    try {
      await _repository.requestPasswordReset(email);
      state = PasswordResetSent(email);
    } on AuthRepositoryException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError('Não foi possível enviar o link de recuperação.');
    }
  }

  /// Reenvia o e-mail de confirmação (RC-02) sem alterar `state`: o
  /// usuário continua em `EmailVerificationPending` durante a chamada -
  /// reenviar não é uma transição de status de autenticação.
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _repository.resendVerificationEmail(email);
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Não foi possível reenviar o e-mail de confirmação.',
      );
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);

/// Deriva o id do usuário logado a partir do AuthStatus, evitando repetir
/// `if (auth is Authenticated)` em cada módulo que precisa da identidade
/// do usuário atual (ex.: DV-02).
final currentUserIdProvider = Provider<String?>((ref) {
  final status = ref.watch(authControllerProvider);
  return status is Authenticated ? status.userId : null;
});
