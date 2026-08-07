import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/deep_link/deep_link.dart';
import '../../../core/deep_link/deep_link_receiver.dart';
import '../presentation/states/pending_invite_state.dart';

/// Guarda o código de convite de grupo recebido por Deep Link
/// (`borah://group/join?invite=X`) até poder ser consumido por
/// `JoinGroupPage`.
///
/// Completamente passivo: nunca abre uma `StreamSubscription`, nunca
/// conhece `DeepLinkService`/`AppDeepLink`/`Router`/`BuildContext`. Só
/// reage a [receive], chamado de fora por `DeepLinkDispatcher` (via
/// [DeepLinkReceiver]) - mesma relação que qualquer outro controller já
/// tem com a fonte de dado que ele escuta, nunca uma exceção à regra.
class PendingInviteController extends Notifier<PendingInviteState>
    implements DeepLinkReceiver {
  @override
  PendingInviteState build() => const NoPendingInvite();

  bool get existe => state is PendingInvite;

  /// Só olha o valor, sem consumir - use [consumir] quando for de fato
  /// usar o código agora.
  String? get codigo => switch (state) {
    PendingInvite(:final inviteCode) => inviteCode,
    NoPendingInvite() => null,
  };

  @override
  void receive(DeepLink link) {
    if (link is! GroupJoinDeepLink) return;
    state = PendingInvite(link.inviteCode);
  }

  /// Devolve o código e limpa o estado - uso único, para quando o
  /// código já vai ser aplicado agora (ex.: `JoinGroupPage` ao montar).
  String? consumir() {
    final code = codigo;
    state = const NoPendingInvite();
    return code;
  }

  /// Descarta sem devolver nada - usuário abandonou o fluxo.
  void limpar() {
    state = const NoPendingInvite();
  }
}

final pendingInviteControllerProvider =
    NotifierProvider<PendingInviteController, PendingInviteState>(
      PendingInviteController.new,
    );
