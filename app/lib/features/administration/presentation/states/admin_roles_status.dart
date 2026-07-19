import '../../../../core/models/paged_result.dart';
import '../../domain/admin_role_repository.dart';

/// Estado da listagem/gestão de papéis administrativos (DV-08 -
/// "Alterar permissões"), sealed class.
sealed class AdminRolesStatus {
  const AdminRolesStatus();
}

final class AdminRolesInitial extends AdminRolesStatus {
  const AdminRolesInitial();
}

final class AdminRolesLoading extends AdminRolesStatus {
  const AdminRolesLoading();
}

final class AdminRolesLoaded extends AdminRolesStatus {
  const AdminRolesLoaded(this.result);

  final PagedResult<AdminRoleEntry> result;
}

final class AdminRolesEmpty extends AdminRolesStatus {
  const AdminRolesEmpty();
}

final class AdminRolesSaving extends AdminRolesStatus {
  const AdminRolesSaving(this.result);

  final PagedResult<AdminRoleEntry> result;
}

final class AdminRolesError extends AdminRolesStatus {
  const AdminRolesError(this.message);

  final String message;
}
