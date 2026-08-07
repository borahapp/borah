import 'deep_link.dart';

/// Quem reage a um [DeepLink] já interpretado - implementado por
/// controllers de feature (ex.: `PendingInviteController`), nunca pelo
/// próprio módulo `core/deep_link/`.
abstract interface class DeepLinkReceiver {
  /// **Estritamente síncrono.** Nunca deve: fazer I/O, navegar, abrir
  /// diálogo, aguardar `Future`, chamar API (rede, banco, storage).
  /// Única responsabilidade: interpretar o [DeepLink] recebido e
  /// atualizar estado local imediatamente - o mesmo tipo de operação
  /// que já é natural para um `Notifier.state = ...`.
  ///
  /// A assinatura já é `void`, nunca `Future<void>`, precisamente para
  /// impedir isso no nível de tipo, não só de convenção - qualquer
  /// implementação que precisar de I/O real (buscar dado remoto antes
  /// de decidir o que fazer com o link, por exemplo) está, por
  /// definição, extrapolando o papel de um [DeepLinkReceiver], e
  /// deveria disparar essa chamada assíncrona *depois*, a partir do
  /// estado que `receive()` já deixou pronto - nunca de dentro dele.
  ///
  /// Deve ignorar silenciosamente qualquer [DeepLink] que não seja da
  /// sua responsabilidade (nunca lançar por receber um tipo
  /// inesperado) - o [DeepLinkDispatcher] distribui o mesmo link para
  /// todos os receptores registrados, cada um decide sozinho o que lhe
  /// interessa.
  void receive(DeepLink link);
}
