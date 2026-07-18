import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

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
      state = EmailVerificationPending(email);
    } on AuthException catch (e) {
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
      state = current == null
          ? const Unauthenticated()
          : Authenticated(userId: current.userId, email: current.email);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError(
        'Não foi possível entrar. Verifique suas credenciais.',
      );
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _repository.signOut();
      state = const Unauthenticated();
    } catch (_) {
      state = const AuthError('Não foi possível encerrar a sessão.');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = const AuthLoading();
    try {
      await _repository.requestPasswordReset(email);
      state = PasswordResetSent(email);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError('Não foi possível enviar o link de recuperação.');
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);
