import '../../../../core/models/paged_result.dart';
import '../../../users/domain/user_profile.dart';

/// Estado da listagem de usuários (DV-08 - Gestão de Usuários), sealed class.
sealed class AdminUsersStatus {
  const AdminUsersStatus();
}

final class AdminUsersInitial extends AdminUsersStatus {
  const AdminUsersInitial();
}

final class AdminUsersLoading extends AdminUsersStatus {
  const AdminUsersLoading();
}

final class AdminUsersLoaded extends AdminUsersStatus {
  const AdminUsersLoaded(this.result);

  final PagedResult<UserProfile> result;
}

final class AdminUsersEmpty extends AdminUsersStatus {
  const AdminUsersEmpty();
}

final class AdminUsersError extends AdminUsersStatus {
  const AdminUsersError(this.message);

  final String message;
}
