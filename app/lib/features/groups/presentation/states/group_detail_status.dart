import '../../domain/group_details.dart';

/// Estado do Detalhe do Grupo (GROUP-02B.1), sealed class - mesmo
/// padrão de `RestaurantDetailStatus`/`ReviewDetailStatus`.
sealed class GroupDetailStatus {
  const GroupDetailStatus();
}

final class GroupDetailInitial extends GroupDetailStatus {
  const GroupDetailInitial();
}

final class GroupDetailLoading extends GroupDetailStatus {
  const GroupDetailLoading();
}

final class GroupDetailLoaded extends GroupDetailStatus {
  const GroupDetailLoaded(this.details);

  final GroupDetails details;
}

final class GroupDetailError extends GroupDetailStatus {
  const GroupDetailError(this.message);

  final String message;
}
