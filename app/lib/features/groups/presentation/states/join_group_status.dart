import '../../domain/group.dart';

/// Estado de "entrar em grupo por código" (ONBOARDING-01) - mesmo
/// padrão de `CreateGroupStatus`: sealed class, um estado por fase da
/// operação única desta tela (não há "load", só "save").
sealed class JoinGroupStatus {
  const JoinGroupStatus();
}

final class JoinGroupInitial extends JoinGroupStatus {
  const JoinGroupInitial();
}

final class JoinGroupSaving extends JoinGroupStatus {
  const JoinGroupSaving();
}

final class JoinGroupSaveSuccess extends JoinGroupStatus {
  const JoinGroupSaveSuccess(this.group);

  final Group group;
}

final class JoinGroupError extends JoinGroupStatus {
  const JoinGroupError(this.message);

  final String message;
}
