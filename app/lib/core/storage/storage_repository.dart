import 'dart:typed_data';

/// Contrato de acesso ao Storage (RC-04B). Nenhuma feature deve acessar
/// um bucket do Supabase Storage diretamente — toda comunicação passa
/// por esta interface (ou, mais acima, por
/// [StorageService]/`AppStorage`).
///
/// Agnóstico de bucket (todo método recebe `bucket` como parâmetro) —
/// adicionar um bucket novo no futuro ("permitir expansão futura", ver
/// RC-04B) não exige nenhuma classe nova, só um nome de bucket a mais.
///
/// Pode lançar [StorageException] — quem chama (sempre [StorageService],
/// nunca uma feature diretamente) é responsável por decidir o que fazer
/// com a falha.
abstract interface class StorageRepository {
  /// Envia [bytes] para `<bucket>/<path>`. Falha se o arquivo já existir
  /// e [upsert] for `false` (padrão) — comportamento nativo do Supabase
  /// Storage, usado para "evitar sobrescrita acidental" (RC-04B).
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    bool upsert = false,
  });

  Future<Uint8List> download({required String bucket, required String path});

  Future<void> delete({required String bucket, required String path});

  /// Só retorna uma URL utilizável se o bucket for público — buckets
  /// privados (ex. `avatars`) devem usar [createSignedUrl].
  String getPublicUrl({required String bucket, required String path});

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  });
}
