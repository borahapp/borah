/// Estado de convite de grupo pendente (Deep Link), sealed class -
/// mesmo formato de `JoinGroupStatus`/`EventsListStatus`, mas sem
/// ciclo de carregamento (não é o resultado de uma chamada de rede,
/// é só "existe um código esperando ser usado, ou não").
sealed class PendingInviteState {
  const PendingInviteState();
}

final class NoPendingInvite extends PendingInviteState {
  const NoPendingInvite();
}

final class PendingInvite extends PendingInviteState {
  const PendingInvite(this.inviteCode);

  final String inviteCode;
}
