import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logger/app_logger.dart';
import 'app_deep_link.dart';
import 'deep_link.dart';
import 'deep_link_receiver.dart';

/// Distribui cada [DeepLink] emitido por [AppDeepLink] para os
/// [DeepLinkReceiver] registrados - o único lugar da arquitetura com
/// uma `StreamSubscription` de Deep Link (nenhum [DeepLinkReceiver] a
/// abre por conta própria).
///
/// **Contrato de isolamento entre receptores**: uma exceção lançada por
/// qualquer [DeepLinkReceiver] nunca pode impedir que os demais
/// recebam o mesmo [DeepLink]. Cada receptor é tratado isoladamente -
/// em caso de erro, o dispatcher só registra o problema
/// (`AppLogger.warning`) e continua distribuindo para os próximos, na
/// ordem em que foram registrados.
///
/// **Comportamento oficial de [UnknownDeepLink]**: nunca é distribuído
/// aos receptores (nenhum deles precisaria fazer nada com ele, então
/// nem chega a perguntar) - é só registrado via `AppLogger.warning` e
/// descartado em silêncio.
///
/// **Ciclo de vida**: existe exatamente uma instância deste dispatcher
/// por execução do app. É criada durante a inicialização (`main.dart`,
/// via [deepLinkDispatcherProvider], lido uma única vez no bootstrap) e
/// permanece viva durante toda a execução, sendo descartada junto com o
/// `ProviderContainer` (nunca antes disso). **Nunca deve ser
/// instanciada dentro de uma página, widget ou controller** - isso
/// criaria uma segunda instância competindo pela mesma `Stream`, o que
/// esta classe não foi desenhada para suportar.
class DeepLinkDispatcher {
  DeepLinkDispatcher({
    required Stream<DeepLink> stream,
    required Iterable<DeepLinkReceiver> receivers,
  }) : _receivers = List.unmodifiable(receivers) {
    _subscription = stream.listen(_onLink);
  }

  final List<DeepLinkReceiver> _receivers;
  late final StreamSubscription<DeepLink> _subscription;

  void _onLink(DeepLink link) {
    if (link is UnknownDeepLink) {
      AppLogger.warning(
        'Deep Link não reconhecido, descartado: ${link.uri}',
        tag: 'deep_link/DeepLinkDispatcher',
      );
      return;
    }

    for (final receiver in _receivers) {
      try {
        receiver.receive(link);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'DeepLinkReceiver (${receiver.runtimeType}) lançou ao processar '
          'um Deep Link - os demais receptores continuam recebendo '
          'normalmente.',
          tag: 'deep_link/DeepLinkDispatcher',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  void dispose() {
    unawaited(_subscription.cancel());
  }
}

/// "Seam" de injeção - a lista real de receptores é definida via
/// `overrideWith` no bootstrap do app (`main.dart`), nunca aqui: este
/// módulo (`core/deep_link/`) nunca importa nenhuma feature. Vazio por
/// padrão para que [deepLinkDispatcherProvider] continue funcionando
/// mesmo sem override (ex.: em testes que não precisam de nenhum
/// receptor real).
final deepLinkReceiversProvider = Provider<List<DeepLinkReceiver>>(
  (ref) => const [],
);

final deepLinkDispatcherProvider = Provider<DeepLinkDispatcher>((ref) {
  final dispatcher = DeepLinkDispatcher(
    stream: AppDeepLink.onLink,
    receivers: ref.watch(deepLinkReceiversProvider),
  );
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});
