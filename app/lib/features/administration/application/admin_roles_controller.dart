import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  static const _limit = 20;

  Future<void> load() {
    _page = 1;
    return _run();
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! AdminRolesLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run();
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
    final current = state;
    if (current is AdminRolesLoaded) {
      state = AdminRolesSaving(current.result);
    }
    try {
      await action();
      await _run();
    } on AdminRoleRepositoryException catch (e) {
      state = AdminRolesError(e.message);
    } catch (_) {
      state = const AdminRolesError('Não foi possível concluir a operação.');
    }
  }

  Future<void> _run() async {
    state = const AdminRolesLoading();
    try {
      final result = await _repository.listAdmins(page: _page, limit: _limit);
      state = result.items.isEmpty
          ? const AdminRolesEmpty()
          : AdminRolesLoaded(result);
    } on AdminRoleRepositoryException catch (e) {
      state = AdminRolesError(e.message);
    } catch (_) {
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
