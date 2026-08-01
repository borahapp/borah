import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/app_storage.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/data/auth_repository_impl.dart';
import '../../authentication/domain/auth_repository.dart';
import '../data/account_deletion_repository_impl.dart';
import '../domain/account_deletion_repository.dart';
import '../presentation/states/account_deletion_status.dart';

/// Orquestra o fluxo completo de exclusão de conta (RC-04C — LGPD/RN-003):
/// reautenticação → limpeza do Storage (best-effort) → exclusão via RPC
/// → logout local. Nenhuma etapa é pulada, e a exclusão em si
/// (`AccountDeletionRepository.deleteOwnAccount`) nunca é engolida — só a
/// limpeza do Storage é best-effort (mesma filosofia de
/// `StorageService.replace`, RC-04B1: uma falha auxiliar não pode
/// bloquear o direito à exclusão dos dados principais).
class AccountDeletionController extends Notifier<AccountDeletionStatus> {
  @override
  AccountDeletionStatus build() => const AccountDeletionInitial();

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  AccountDeletionRepository get _accountDeletionRepository =>
      ref.read(accountDeletionRepositoryProvider);

  /// [email] é sempre fornecido por quem chama (a tela lê
  /// `authControllerProvider`) — mesma disciplina de "core/ nunca
  /// resolve o usuário sozinho" já aplicada a `FeedbackDialog` (RC-03E),
  /// estendida aqui mesmo sendo uma feature, para manter o controller
  /// puro e testável sem depender de qual provider expõe a sessão atual.
  Future<void> deleteAccount({
    required String email,
    required String password,
    String? avatarPath,
  }) async {
    state = const AccountDeletionInProgress();

    try {
      // Reautenticação: confirma a senha antes de uma ação irreversível
      // (RC-04C §UX — "evitar exclusões acidentais"). Chama o
      // repositório diretamente (não `AuthController.signIn`), para não
      // disparar os efeitos colaterais de um login de verdade
      // (`AppAnalytics.identify`/`trackLoginSuccess`) durante uma
      // simples confirmação de identidade.
      await _authRepository.signIn(email: email, password: password);
    } on AuthRepositoryException catch (e) {
      state = AccountDeletionReauthenticationError(e.message);
      return;
    } catch (_) {
      state = const AccountDeletionReauthenticationError(
        'Não foi possível confirmar sua senha.',
      );
      return;
    }

    if (avatarPath != null) {
      try {
        await AppStorage.delete(bucket: 'avatars', path: avatarPath);
      } catch (e, stackTrace) {
        // Best-effort - ver documentação da classe. O avatar órfão fica
        // registrado para limpeza futura, mas nunca bloqueia a exclusão
        // da conta em si.
        AppLogger.warning(
          'Falha ao apagar avatar durante exclusão de conta.',
          tag: 'users/AccountDeletionController.deleteAccount',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    try {
      await _accountDeletionRepository.deleteOwnAccount();
    } on AccountDeletionRepositoryException catch (e) {
      state = AccountDeletionError(e.message);
      return;
    } catch (_) {
      state = const AccountDeletionError(
        'Não foi possível excluir sua conta. Tente novamente.',
      );
      return;
    }

    // Disparado antes do signOut() abaixo de propósito: signOut() já
    // chama `AppAnalytics.reset()` internamente (ver AuthController),
    // que limparia o userId identificado antes deste evento sair.
    unawaited(AppAnalytics.trackAccountDeleted());

    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (e, stackTrace) {
      // Best-effort - a conta já foi excluída no servidor; uma falha ao
      // encerrar a sessão local não deve impedir o usuário de ver a
      // confirmação de sucesso e ser levado ao Login. Mesmo padrão de
      // log do bloco de limpeza do Storage acima: best-effort não é
      // sinônimo de silencioso.
      AppLogger.warning(
        'Falha ao encerrar sessão local após exclusão de conta.',
        tag: 'users/AccountDeletionController.deleteAccount',
        error: e,
        stackTrace: stackTrace,
      );
    }

    state = const AccountDeletionSuccess();
  }

  /// Volta ao estado inicial — chamado sempre que o diálogo de exclusão
  /// é reaberto, mesma disciplina de `FeedbackController.reset()` (RC-03E).
  void reset() => state = const AccountDeletionInitial();
}

final accountDeletionControllerProvider =
    NotifierProvider<AccountDeletionController, AccountDeletionStatus>(
      AccountDeletionController.new,
    );
