import 'dart:async';

import 'package:app_links/app_links.dart';

import '../logger/app_logger.dart';
import 'deep_link.dart';
import 'deep_link_parser.dart';
import 'deep_link_service.dart';

/// Única classe do projeto que importa `package:app_links` - a mesma
/// fronteira que `SupabaseStorageService` já cumpre para o SDK de
/// Storage. Toda interpretação de `Uri` é delegada a [DeepLinkParser];
/// esta classe só resolve *como capturar* a `Uri` (esquema customizado
/// hoje - `borah://`; App Links/Universal Links reais quando a
/// verificação de domínio estiver pronta usam a mesma API do pacote,
/// sem mudar esta classe).
class AppLinksDeepLinkService implements DeepLinkService {
  AppLinksDeepLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;
  Stream<DeepLink>? _onLink;

  @override
  Stream<DeepLink> get onLink => _onLink ??= _buildStream();

  /// Combina o link de cold start (`getInitialLink()`, único, ouvido só
  /// na primeira inscrição) com os recebidos depois (`uriLinkStream`) -
  /// um único `Stream` broadcast, para que `DeepLinkDispatcher` nunca
  /// precise diferenciar as duas origens.
  Stream<DeepLink> _buildStream() {
    late final StreamController<DeepLink> controller;
    controller = StreamController<DeepLink>.broadcast(
      onListen: () async {
        final initial = await _appLinks.getInitialLink();
        if (initial != null) {
          controller.add(DeepLinkParser.parse(initial));
        }
      },
    );

    _appLinks.uriLinkStream.listen(
      (uri) => controller.add(DeepLinkParser.parse(uri)),
      onError: (Object error, StackTrace stackTrace) {
        // DeepLinkParser.parse nunca lança (ver contrato) - um erro
        // aqui só pode vir do próprio transporte (app_links), nunca da
        // interpretação da Uri. Registrado, nunca propagado - um Deep
        // Link com falha de transporte não deveria derrubar o app.
        AppLogger.warning(
          'Falha no transporte de Deep Link (app_links)',
          tag: 'deep_link/AppLinksDeepLinkService',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    return controller.stream;
  }
}
