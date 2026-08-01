import '../../domain/group.dart';

/// Estado de edição de grupo (BLOCO 2) - mesmo padrão de
/// `CreateGroupStatus`: sealed class, um estado por fase da operação
/// única desta tela.
sealed class EditGroupStatus {
  const EditGroupStatus();
}

final class EditGroupInitial extends EditGroupStatus {
  const EditGroupInitial();
}

final class EditGroupSaving extends EditGroupStatus {
  const EditGroupSaving();
}

final class EditGroupSaveSuccess extends EditGroupStatus {
  const EditGroupSaveSuccess(this.group);

  final Group group;
}

final class EditGroupError extends EditGroupStatus {
  const EditGroupError(this.message);

  final String message;
}
