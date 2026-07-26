import 'dart:math';

final _random = Random.secure();

/// Extrai e normaliza a extensão de um nome de arquivo (RC-04B —
/// "normalização do nome"): tudo em minúsculas, só o último segmento
/// após o último `.`. Não faz nenhuma validação de segurança por si só
/// — quem chama ainda precisa checar o resultado contra uma lista de
/// extensões permitidas antes de usá-lo (ver [StorageUploadConfig]).
String normalizeExtension(String fileName) {
  final withoutQuery = fileName.split('?').first;
  final segments = withoutQuery.split('.');
  if (segments.length < 2) return '';
  return segments.last.toLowerCase().trim();
}

/// Gera um nome de arquivo seguro e imprevisível — nunca reaproveita o
/// nome enviado pelo usuário (RC-04B — "não utilizar nomes enviados
/// pelo usuário"), evitando path traversal e colisão/sobrescrita
/// acidental por construção: o resultado é sempre
/// `<timestamp em microssegundos>-<sufixo aleatório hex>.<extensão>`,
/// nunca uma string interpolada a partir do nome original.
///
/// [extension] deve já ter sido validada contra uma lista de extensões
/// permitidas antes de chegar aqui (ver [StorageService.upload]) — esta
/// função só a usa como sufixo do nome gerado, nunca aceita nenhuma
/// outra parte do nome original do arquivo.
///
/// `@visibleForTesting`-equivalente por ser uma função top-level pura
/// (sem I/O, sem SDK) — testável em isolamento, mesmo padrão já usado
/// em `flattenAnalyticsEventForPostHog` (RC-03C).
String generateStorageFileName(String extension) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final randomSuffix = List.generate(
    8,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();
  return '$timestamp-$randomSuffix.$extension';
}
