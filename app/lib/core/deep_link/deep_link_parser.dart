import 'deep_link.dart';

/// Interpreta uma `Uri` de Deep Link como [DeepLink] - responsabilidade
/// única, sem transporte (nada de `app_links`, Push ou QR Code aqui).
/// Reutilizável por qualquer transporte futuro e por testes, sem mock
/// nenhum.
///
/// Convenção reconhecida: `borah://<domínio>/<ação>?<payload>` (ver a
/// regra arquitetural documentada em [DeepLink]) - e, equivalentemente,
/// `https://appborah.com.br/<domínio>/<ação>?<payload>` (App Links/
/// Universal Links, item 4 da rodada de melhorias pós-FASE 08: um link
/// `https` é clicável automaticamente em apps de mensagem como WhatsApp/
/// SMS, diferente do esquema customizado `borah://`, que chega como
/// texto puro). Aceita `appborah.com.br` e `www.appborah.com.br` (CNAME
/// do GitHub Pages aponta para o subdomínio `www`) - a verificação
/// nativa (`assetlinks.json`/`apple-app-site-association`) fica restrita
/// a um único domínio canônico, mas o parser em si é tolerante aos dois.
abstract final class DeepLinkParser {
  /// Contrato formal, nunca violado por nenhuma implementação futura
  /// desta função:
  /// - **Determinístico**: a mesma `Uri` sempre produz o mesmo
  ///   [DeepLink] - nunca depende de estado externo, hora, rede ou I/O.
  /// - **Nunca lança exceção**: qualquer falha ao interpretar host/
  ///   path/query (URI malformada, parâmetro ausente, tipo inesperado)
  ///   é capturada aqui dentro e vira [UnknownDeepLink] - nunca
  ///   propaga. Mesmo papel de fronteira de segurança para dado externo
  ///   que `StorageService` já cumpre para bytes de upload.
  /// - **Nunca retorna `null`**: toda `Uri`, reconhecida ou não, gera
  ///   exatamente um [DeepLink].
  /// - **Nunca é `async`/`Future`**: é interpretação pura de texto, sem
  ///   motivo para ser assíncrona - o que permite chamar de qualquer
  ///   transporte (síncrono ou não) sem acoplar a assinatura a nenhum
  ///   deles.
  static DeepLink parse(Uri uri) {
    try {
      return _parse(uri);
    } catch (_) {
      return UnknownDeepLink(uri: uri);
    }
  }

  static DeepLink _parse(Uri uri) {
    final String domain;
    final String action;

    if (uri.scheme == 'borah') {
      domain = uri.host;
      action = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    } else if (uri.scheme == 'https' &&
        _isAppDomain(uri.host) &&
        uri.pathSegments.length >= 2) {
      // `https://appborah.com.br/<domínio>/<ação>?<payload>` - mesma
      // convenção domínio/ação do `borah://`, só que como os 2 primeiros
      // segmentos do path em vez de host+primeiro segmento (o host aqui
      // é o domínio DNS, não o domínio do Deep Link).
      domain = uri.pathSegments[0];
      action = uri.pathSegments[1];
    } else {
      return UnknownDeepLink(uri: uri);
    }

    if (domain == 'group' && action == 'join') {
      final invite = uri.queryParameters['invite'];
      if (invite == null || invite.isEmpty) return UnknownDeepLink(uri: uri);
      return GroupJoinDeepLink(inviteCode: invite);
    }

    return UnknownDeepLink(uri: uri);
  }

  static bool _isAppDomain(String host) =>
      host == 'appborah.com.br' || host == 'www.appborah.com.br';
}
