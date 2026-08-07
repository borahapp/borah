import 'deep_link.dart';

/// Interpreta uma `Uri` de Deep Link como [DeepLink] - responsabilidade
/// única, sem transporte (nada de `app_links`, Push ou QR Code aqui).
/// Reutilizável por qualquer transporte futuro e por testes, sem mock
/// nenhum.
///
/// Convenção reconhecida: `borah://<domínio>/<ação>?<payload>` (ver a
/// regra arquitetural documentada em [DeepLink]).
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
    if (uri.scheme != 'borah') return UnknownDeepLink(uri: uri);

    final domain = uri.host;
    final action = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';

    if (domain == 'group' && action == 'join') {
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) return UnknownDeepLink(uri: uri);
      return GroupJoinDeepLink(inviteCode: code);
    }

    return UnknownDeepLink(uri: uri);
  }
}
