import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthException;

import '../../../core/errors/supabase_error_translator.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/auth_repository.dart';
import 'auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(
      () => _datasource.signUp(name: name, email: email, password: password),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(() => _datasource.signIn(email: email, password: password));
  }

  @override
  Future<void> signOut() => _guard(_datasource.signOut);

  @override
  Future<void> requestPasswordReset(String email) {
    return _guard(() => _datasource.requestPasswordReset(email));
  }

  @override
  Future<void> updatePassword(String newPassword) {
    return _guard(() => _datasource.updatePassword(newPassword));
  }

  @override
  Future<void> resendVerificationEmail(String email) {
    return _guard(() => _datasource.resendVerificationEmail(email));
  }

  @override
  Future<void> signInWithGoogle() => _guard(_datasource.signInWithGoogle);

  @override
  Future<void> signInWithApple() => _guard(_datasource.signInWithApple);

  @override
  Future<void> signInWithFacebook() => _guard(_datasource.signInWithFacebook);

  @override
  Future<void> signInAnonymously() => _guard(_datasource.signInAnonymously);

  /// Traduz `AuthException` (supabase_flutter) para `AuthRepositoryException`,
  /// para que nenhuma camada acima de `data/` precise conhecer o Supabase.
  /// Mensagem já traduzida para português (RC-04E) nos fluxos cobertos por
  /// `SupabaseErrorTranslator`.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      throw AuthRepositoryException(
        SupabaseErrorTranslator.translateAuthError(e),
      );
    }
  }

  @override
  AuthUserData? get currentUser {
    final user = _datasource.currentSession?.user;
    if (user == null) return null;
    return (userId: user.id, email: user.email);
  }

  @override
  Stream<AuthSessionUpdate> get onAuthStateChange {
    return _datasource.onAuthStateChange
        .map<AuthSessionUpdate>((state) {
          final user = state.session?.user;
          final event = switch (state.event) {
            AuthChangeEvent.passwordRecovery =>
              AuthSessionEvent.passwordRecovery,
            AuthChangeEvent.signedOut => AuthSessionEvent.signedOut,
            _ =>
              user == null
                  ? AuthSessionEvent.signedOut
                  : AuthSessionEvent.signedIn,
          };
          return (
            event: event,
            user: user == null ? null : (userId: user.id, email: user.email),
          );
        })
        .handleError((Object error, StackTrace stackTrace) {
          // RC-04E: link de recuperação inválido/expirado chega aqui como
          // erro do stream (`GoTrueClient.notifyException`), não como
          // dado - traduzido do mesmo jeito que qualquer outro erro de
          // autenticação, para manter o domínio livre do tipo do Supabase.
          if (error is AuthException) {
            throw AuthRepositoryException(
              SupabaseErrorTranslator.translateAuthError(error),
            );
          }
          throw error;
        });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(AuthRemoteDatasource(client));
});
