import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'storage_service.dart';
import 'storage_upload_config.dart';
import 'supabase_storage_service.dart';

/// Fachada estática de Storage do BORAH (RC-04B) — mesmo padrão
/// arquitetural de `AppLogger`/`CrashReporting`/`AppAnalytics`/
/// `AppFeatureFlags`/`AppFeedback` (RC-03A-E). Toda feature deve chamar
/// só os métodos daqui; nenhuma tela deve importar o SDK do Supabase
/// Storage nem conhecer [StorageRepository]/[StorageService]
/// diretamente.
///
/// Uso típico:
/// ```dart
/// final path = await AppStorage.upload(
///   bucket: 'avatars',
///   folder: userId,
///   bytes: bytes,
///   originalFileName: pickedFile.name,
///   contentType: 'image/jpeg',
///   config: StorageUploadConfig.avatar,
/// );
/// final url = await AppStorage.getSignedUrl(bucket: 'avatars', path: path);
/// ```
abstract final class AppStorage {
  /// Sobrescreve o serviço em testes (`test/`), no lugar do serviço
  /// padrão (Supabase real). Nunca deve ser usado em código de produção.
  @visibleForTesting
  static StorageService? debugServiceOverride;

  static StorageService? _defaultService;

  /// Criado sob demanda (não no carregamento da classe) para não exigir
  /// que `Supabase.instance.client` já exista no momento em que este
  /// arquivo é importado — só quando `AppStorage` é de fato usado pela
  /// primeira vez, o que deve ocorrer depois de `initializeSupabase()`
  /// (ver `main.dart`).
  static StorageService get _service {
    return debugServiceOverride ??
        (_defaultService ??= StorageService(
          SupabaseStorageService(Supabase.instance.client),
        ));
  }

  static Future<String> upload({
    required String bucket,
    required String folder,
    required Uint8List bytes,
    required String originalFileName,
    required String contentType,
    required StorageUploadConfig config,
  }) {
    return _service.upload(
      bucket: bucket,
      folder: folder,
      bytes: bytes,
      originalFileName: originalFileName,
      contentType: contentType,
      config: config,
    );
  }

  static Future<String> replace({
    required String bucket,
    required String folder,
    required Uint8List bytes,
    required String originalFileName,
    required String contentType,
    required StorageUploadConfig config,
    String? previousPath,
  }) {
    return _service.replace(
      bucket: bucket,
      folder: folder,
      bytes: bytes,
      originalFileName: originalFileName,
      contentType: contentType,
      config: config,
      previousPath: previousPath,
    );
  }

  static Future<Uint8List> download({
    required String bucket,
    required String path,
  }) {
    return _service.download(bucket: bucket, path: path);
  }

  static Future<void> delete({required String bucket, required String path}) {
    return _service.delete(bucket: bucket, path: path);
  }

  static String getPublicUrl({required String bucket, required String path}) {
    return _service.getPublicUrl(bucket: bucket, path: path);
  }

  static Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) {
    return _service.createSignedUrl(
      bucket: bucket,
      path: path,
      expiresInSeconds: expiresInSeconds,
    );
  }
}
