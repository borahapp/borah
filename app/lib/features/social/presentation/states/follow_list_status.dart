import '../../../../core/models/paged_result.dart';
import '../../../users/domain/user_profile.dart';

/// Tipo de listagem (DV-07 §6: telas "Seguidores" e "Seguindo" separadas,
/// mesma consulta parametrizada por direção).
enum FollowListType { followers, following }

/// Estado da listagem de seguidores/seguindo (DV-07), sealed class.
sealed class FollowListStatus {
  const FollowListStatus();
}

final class FollowListInitial extends FollowListStatus {
  const FollowListInitial();
}

final class FollowListLoading extends FollowListStatus {
  const FollowListLoading();
}

final class FollowListLoaded extends FollowListStatus {
  const FollowListLoaded(this.result);

  final PagedResult<UserProfile> result;
}

final class FollowListEmpty extends FollowListStatus {
  const FollowListEmpty();
}

final class FollowListError extends FollowListStatus {
  const FollowListError(this.message);

  final String message;
}
