import 'deep_link.dart';

/// Contrato de transporte de Deep Link - agnóstico de mecanismo
/// (esquema customizado, App Links/Universal Links, Push Notification,
/// QR Code...). A única implementação real hoje
/// ([AppLinksDeepLinkService]) usa `package:app_links`; nenhum
/// consumidor deste contrato precisa saber disso.
abstract interface class DeepLinkService {
  /// Emite cada Deep Link recebido, já interpretado (nunca `Uri` crua -
  /// toda interpretação é responsabilidade de `DeepLinkParser`,
  /// chamado internamente pela implementação). Inclui, como primeira
  /// emissão quando existir, o link que abriu o app do zero (cold
  /// start) - nenhum consumidor precisa distinguir esse caso do de um
  /// link recebido com o app já aberto.
  Stream<DeepLink> get onLink;
}
