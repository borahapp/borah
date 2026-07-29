import 'dart:typed_data';

import '../logger/app_logger.dart';
import 'storage_exception.dart';
import 'storage_filename.dart';
import 'storage_magic_bytes.dart';
import 'storage_repository.dart';
import 'storage_upload_config.dart';

/// Orquestra [StorageRepository] + validação de segurança (RC-04B):
/// tamanho máximo, MIME permitido, extensão permitida, nome de arquivo
/// sempre gerado (nunca o nome enviado pelo usuário) e uma pasta segura
/// (sem `..`/barras, evitando path traversal).
///
/// Mesma filosofia de erro de `FeedbackService` (RC-03E), não de
/// `FeatureFlagService` (RC-03D): existe sempre um chamador aguardando
/// o resultado de forma síncrona (upload de uma imagem tem um estado de
/// UI real), então [StorageException] se propaga — nunca é engolida
/// aqui.
class StorageService {
  StorageService(this._repository);

  final StorageRepository _repository;

  /// Envia um novo arquivo para `<bucket>/<folder>/<nome gerado>`.
  /// [originalFileName] é usado só para extrair a extensão (já validada
  /// contra [config].allowedExtensions) — nunca vira parte do caminho
  /// final (ver `generateStorageFileName`).
  Future<String> upload({
    required String bucket,
    required String folder,
    required Uint8List bytes,
    required String originalFileName,
    required String contentType,
    required StorageUploadConfig config,
  }) async {
    _assertSafeFolder(folder);
    final extension = _validate(
      bytes: bytes,
      originalFileName: originalFileName,
      contentType: contentType,
      config: config,
    );

    final path = '$folder/${generateStorageFileName(extension)}';
    return _repository.upload(
      bucket: bucket,
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Envia um novo arquivo e, em caso de sucesso, remove o anterior
  /// (best-effort). A ordem é deliberada: só apaga [previousPath] DEPOIS
  /// do novo upload ter sucesso — nunca deixa o usuário sem nenhum
  /// arquivo caso o upload falhe. Uma falha ao apagar o arquivo antigo
  /// não desfaz o upload novo nem propaga erro (o resultado principal
  /// da operação, do ponto de vista do usuário, já foi alcançado).
  Future<String> replace({
    required String bucket,
    required String folder,
    required Uint8List bytes,
    required String originalFileName,
    required String contentType,
    required StorageUploadConfig config,
    String? previousPath,
  }) async {
    final newPath = await upload(
      bucket: bucket,
      folder: folder,
      bytes: bytes,
      originalFileName: originalFileName,
      contentType: contentType,
      config: config,
    );

    if (previousPath != null && previousPath != newPath) {
      try {
        await _repository.delete(bucket: bucket, path: previousPath);
      } catch (e, stackTrace) {
        // Best-effort - ver documentação do método acima. Não propaga,
        // mas registra (RC-04B1 - achado da auditoria: sem isso, o
        // arquivo antigo vira órfão sem nenhuma telemetria, violando
        // AR-08 §16 "Monitoramento: arquivos órfãos/falhas de upload").
        AppLogger.warning(
          'Falha ao remover arquivo antigo após replace() - possível '
          'arquivo órfão em "$bucket/$previousPath".',
          tag: 'storage/StorageService.replace',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    return newPath;
  }

  /// `async` é necessário mesmo delegando diretamente ao repositório:
  /// garante que uma exceção síncrona (ex.: mock em teste via
  /// `thenThrow`) seja empacotada como rejeição da `Future` retornada,
  /// em vez de lançar sincronamente na chamada (mesma lição já aplicada
  /// a `FeedbackService.submit`, RC-03E).
  Future<Uint8List> download({
    required String bucket,
    required String path,
  }) async {
    return _repository.download(bucket: bucket, path: path);
  }

  Future<void> delete({required String bucket, required String path}) async {
    return _repository.delete(bucket: bucket, path: path);
  }

  String getPublicUrl({required String bucket, required String path}) {
    return _repository.getPublicUrl(bucket: bucket, path: path);
  }

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    return _repository.createSignedUrl(
      bucket: bucket,
      path: path,
      expiresInSeconds: expiresInSeconds,
    );
  }

  /// Retorna a extensão já normalizada, para reaproveitar no caminho
  /// final sem recalculá-la.
  String _validate({
    required Uint8List bytes,
    required String originalFileName,
    required String contentType,
    required StorageUploadConfig config,
  }) {
    if (bytes.isEmpty) {
      throw const StorageException('O arquivo está vazio.');
    }
    if (bytes.lengthInBytes > config.maxBytes) {
      final maxMb = (config.maxBytes / (1024 * 1024)).toStringAsFixed(0);
      throw StorageException('O arquivo deve ter no máximo $maxMb MB.');
    }
    if (!config.allowedMimeTypes.contains(contentType)) {
      throw const StorageException('Formato de arquivo não suportado.');
    }
    final extension = normalizeExtension(originalFileName);
    if (!config.allowedExtensions.contains(extension)) {
      throw const StorageException('Formato de arquivo não suportado.');
    }
    // RC-04B1 - achado da auditoria: nem o cliente nem o Supabase
    // Storage validam os bytes reais do arquivo, só o Content-Type/
    // extensão declarados (ver RC-04B_STORAGE_SECURITY.md §RC-04B1
    // Hardening). Esta checagem fecha essa lacuna para o caminho
    // legítimo do app.
    if (!matchesImageSignature(bytes, extension)) {
      throw const StorageException(
        'O conteúdo do arquivo não corresponde ao formato declarado.',
      );
    }
    return extension;
  }

  /// "Evitar path traversal" (RC-04B): [folder] é sempre um identificador
  /// controlado pelo próprio app (ex.: um UUID de usuário/restaurante/
  /// avaliação), nunca texto livre digitado por alguém — mesmo assim,
  /// esta checagem defensiva impede que um valor malformado alcance o
  /// Storage.
  void _assertSafeFolder(String folder) {
    if (folder.isEmpty ||
        folder.contains('..') ||
        folder.contains('/') ||
        folder.contains(r'\')) {
      throw const StorageException('Não foi possível preparar o upload.');
    }
  }
}
