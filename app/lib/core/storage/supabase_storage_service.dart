import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase_storage
    show StorageException;

import 'storage_exception.dart';
import 'storage_repository.dart';

/// Única classe do projeto que consulta o Supabase Storage diretamente
/// (RC-04B) — mesmo papel que `SupabaseFeedbackRepository`/
/// `SupabaseFeatureFlagRepository` desempenham para suas respectivas
/// tabelas (RC-03D/E): a única fronteira com o SDK.
///
/// Nomeada `SupabaseStorageService` (não `SupabaseStorageRepository`,
/// apesar de implementar `StorageRepository`) - nome exigido
/// explicitamente pela especificação desta rodada.
///
/// O pacote `supabase_flutter` também exporta uma classe própria
/// `StorageException` — por isso o import acima esconde a deles
/// (`hide`) e a reimporta com prefixo (`as supabase_storage`), para que
/// o nome `StorageException` sem prefixo, em todo este arquivo, sempre
/// se refira à exceção própria do BORAH (`storage_exception.dart`).
class SupabaseStorageService implements StorageRepository {
  SupabaseStorageService(this._client);

  final SupabaseClient _client;

  @override
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    bool upsert = false,
  }) {
    return _guard(() async {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: upsert),
          );
      return path;
    });
  }

  @override
  Future<String> update({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) {
    return _guard(() async {
      await _client.storage
          .from(bucket)
          .updateBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
      return path;
    });
  }

  @override
  Future<Uint8List> download({required String bucket, required String path}) {
    return _guard(() => _client.storage.from(bucket).download(path));
  }

  @override
  Future<void> delete({required String bucket, required String path}) {
    return _guard(() => _client.storage.from(bucket).remove([path]));
  }

  @override
  String getPublicUrl({required String bucket, required String path}) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) {
    return _guard(
      () =>
          _client.storage.from(bucket).createSignedUrl(path, expiresInSeconds),
    );
  }

  /// Nunca expõe a mensagem interna do Supabase (RC-04B §Tratamento de
  /// erros) — sempre traduzida para [StorageException], a única exceção
  /// que atravessa esta fronteira.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on supabase_storage.StorageException catch (e) {
      throw StorageException(e.message);
    } catch (_) {
      throw const StorageException(
        'Não foi possível concluir a operação de armazenamento.',
      );
    }
  }
}
