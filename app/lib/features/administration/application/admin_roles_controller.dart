import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../data/admin_role_repository_impl.dart';
import '../data/audit_log_repository_impl.dart';
import '../domain/admin_role_repository.dart';
import '../domain/audit_log_repository.dart';
import '../presentation/states/admin_roles_status.dart';

/// Gestão de papéis administrativos (DV-08 - "Alterar permissões").
/// Concessão/revogação só é permitida a `super_admin` - autorizado pela
/// RLS de `user_roles`, não verificado aqui; uma tentativa sem permissão
/// chega como `AdminRolesError`.
class AdminRolesController extends Notifier<AdminRolesStatus> {
  @override
  AdminRolesStatus build() => const AdminRolesInitial();

  AdminRoleRepository get _repository => ref.read(adminRoleRepositoryProvider);
  AuditLogRepository get _auditLogRepository =>
      ref.read(auditLogRepositoryProvider);

  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> load() {
    _page = 1;
    return _run(const AdminRolesLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! AdminRolesLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  Future<void> grantRole(
    String userId,
    String role, {
    required String actorId,
  }) {
    return _mutate(() async {
      await _repository.grantRole(userId, role);
      await _auditLogRepository.log(
        actorId: actorId,
        action: 'grant_admin_role',
        entity: 'user',
        entityId: userId,
        metadata: {'role': role},
      );
    });
  }

  Future<void> revokeRole(String userId, {required String actorId}) {
    return _mutate(() async {
      await _repository.revokeRole(userId);
      await _auditLogRepository.log(
        actorId: actorId,
        action: 'revoke_admin_role',
        entity: 'user',
        entityId: userId,
      );
    });
  }

  Future<void> _mutate(Future<void> Function() action) async {
    // Reivindica a geração antes de qualquer `await` (mesmo mecanismo de
    // `AdminRestaurantsController.updateStatus`).
    final requestId = ++_requestId;
    final current = state;
    if (current is AdminRolesLoaded) {
      state = AdminRolesSaving(current.result);
    }
    try {
      await action();
      if (requestId != _requestId) return;
      // Volta para a página 1: mesma simplificação de
      // `AdminRestaurantsController.updateStatus`.
      _page = 1;
      await _run(const AdminRolesLoading(), requestId: requestId);
    } on AdminRoleRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = AdminRolesError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = const AdminRolesError('Não foi possível concluir a operação.');
    }
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `AdminRestaurantsController._run`).
  Future<void> _run(
    AdminRolesStatus loadingState, {
    List<AdminRoleEntry> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listAdmins(page: _page, limit: _limit);
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const AdminRolesEmpty()
          : AdminRolesLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on AdminRoleRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      // Reverte `_page`: a página que falhou nunca chegou a ser aplicada,
      // então a próxima tentativa deve rebuscá-la, em vez de pular para a
      // seguinte.
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = AdminRolesError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const AdminRolesError(
        'Não foi possível carregar os administradores.',
      );
    }
  }
}

final adminRolesControllerProvider =
    NotifierProvider<AdminRolesController, AdminRolesStatus>(
      AdminRolesController.new,
    );
