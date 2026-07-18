import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

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

  /// Traduz `AuthException` (supabase_flutter) para `AuthRepositoryException`,
  /// para que nenhuma camada acima de `data/` precise conhecer o Supabase.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  @override
  AuthUserData? get currentUser {
    final user = _datasource.currentSession?.user;
    if (user == null) return null;
    return (userId: user.id, email: user.email);
  }

  @override
  Stream<AuthUserData?> get onAuthStateChange {
    return _datasource.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return (userId: user.id, email: user.email);
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(AuthRemoteDatasource(client));
});
