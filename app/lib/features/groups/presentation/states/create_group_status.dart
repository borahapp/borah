import '../../domain/group.dart';

/// Estado da criacao de grupo (GROUP-02A) - mesmo padrao de
/// `RestaurantDetailStatus`: sealed class, um estado por fase da
/// operacao unica desta tela (nao ha "load", so "save").
sealed class CreateGroupStatus {
  const CreateGroupStatus();
}

final class CreateGroupInitial extends CreateGroupStatus {
  const CreateGroupInitial();
}

final class CreateGroupSaving extends CreateGroupStatus {
  const CreateGroupSaving();
}

final class CreateGroupSaveSuccess extends CreateGroupStatus {
  const CreateGroupSaveSuccess(this.group);

  final Group group;
}

final class CreateGroupError extends CreateGroupStatus {
  const CreateGroupError(this.message);

  final String message;
}
