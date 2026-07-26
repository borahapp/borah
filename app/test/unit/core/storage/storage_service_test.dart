import 'dart:typed_data';

import 'package:app/core/storage/storage_exception.dart';
import 'package:app/core/storage/storage_repository.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/core/storage/storage_upload_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

const _config = StorageUploadConfig(
  maxBytes: 10,
  allowedMimeTypes: {'image/jpeg', 'image/png'},
  allowedExtensions: {'jpg', 'jpeg', 'png'},
);

Uint8List _bytes([int length = 5]) => Uint8List(length);

void main() {
  late MockStorageRepository repository;
  late StorageService service;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockStorageRepository();
    service = StorageService(repository);

    when(
      () => repository.upload(
        bucket: any(named: 'bucket'),
        path: any(named: 'path'),
        bytes: any(named: 'bytes'),
        contentType: any(named: 'contentType'),
        upsert: any(named: 'upsert'),
      ),
    ).thenAnswer(
      (invocation) async => invocation.namedArguments[#path] as String,
    );
  });

  group('upload() - caminho feliz', () {
    test('gera um caminho `<folder>/<nome gerado>` e nunca usa o nome '
        'original do arquivo', () async {
      final path = await service.upload(
        bucket: 'avatars',
        folder: 'user-1',
        bytes: _bytes(),
        originalFileName: 'foto-pessoal-do-usuario.jpg',
        contentType: 'image/jpeg',
        config: _config,
      );

      expect(path, startsWith('user-1/'));
      expect(path, endsWith('.jpg'));
      expect(path, isNot(contains('foto-pessoal-do-usuario')));
    });

    test('repassa bucket/bytes/contentType ao repositório', () async {
      final bytes = _bytes();

      await service.upload(
        bucket: 'restaurants',
        folder: 'restaurant-1',
        bytes: bytes,
        originalFileName: 'capa.png',
        contentType: 'image/png',
        config: _config,
      );

      verify(
        () => repository.upload(
          bucket: 'restaurants',
          path: any(named: 'path'),
          bytes: bytes,
          contentType: 'image/png',
          upsert: false,
        ),
      ).called(1);
    });
  });

  group('upload() - validação de tamanho', () {
    test('rejeita arquivo maior que maxBytes sem chamar o repositório', () {
      expect(
        () => service.upload(
          bucket: 'avatars',
          folder: 'user-1',
          bytes: _bytes(11),
          originalFileName: 'foto.jpg',
          contentType: 'image/jpeg',
          config: _config,
        ),
        throwsA(isA<StorageException>()),
      );
      verifyNever(
        () => repository.upload(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          upsert: any(named: 'upsert'),
        ),
      );
    });

    test('rejeita arquivo vazio', () {
      expect(
        () => service.upload(
          bucket: 'avatars',
          folder: 'user-1',
          bytes: Uint8List(0),
          originalFileName: 'foto.jpg',
          contentType: 'image/jpeg',
          config: _config,
        ),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('upload() - validação de MIME/extensão', () {
    test('rejeita content-type fora da allowlist', () {
      expect(
        () => service.upload(
          bucket: 'avatars',
          folder: 'user-1',
          bytes: _bytes(),
          originalFileName: 'foto.jpg',
          contentType: 'application/pdf',
          config: _config,
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('rejeita extensão fora da allowlist mesmo com MIME permitido', () {
      expect(
        () => service.upload(
          bucket: 'avatars',
          folder: 'user-1',
          bytes: _bytes(),
          originalFileName: 'foto.gif',
          contentType: 'image/jpeg',
          config: _config,
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('normaliza a extensão em maiúsculas antes de validar', () async {
      final path = await service.upload(
        bucket: 'avatars',
        folder: 'user-1',
        bytes: _bytes(),
        originalFileName: 'FOTO.PNG',
        contentType: 'image/png',
        config: _config,
      );

      expect(path, endsWith('.png'));
    });
  });

  group('upload() - path traversal', () {
    test('rejeita folder contendo ".."', () {
      expect(
        () => service.upload(
          bucket: 'avatars',
          folder: '../etc',
          bytes: _bytes(),
          originalFileName: 'foto.jpg',
          contentType: 'image/jpeg',
          config: _config,
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('rejeita folder contendo barra', () {
      expect(
        () => service.upload(
          bucket: 'avatars',
          folder: 'a/b',
          bytes: _bytes(),
          originalFileName: 'foto.jpg',
          contentType: 'image/jpeg',
          config: _config,
        ),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('replace()', () {
    test('faz upload do novo arquivo e depois apaga o anterior', () async {
      when(
        () => repository.delete(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
        ),
      ).thenAnswer((_) async {});

      final newPath = await service.replace(
        bucket: 'avatars',
        folder: 'user-1',
        bytes: _bytes(),
        originalFileName: 'foto.jpg',
        contentType: 'image/jpeg',
        config: _config,
        previousPath: 'user-1/old.jpg',
      );

      expect(newPath, isNot('user-1/old.jpg'));
      verify(
        () => repository.delete(bucket: 'avatars', path: 'user-1/old.jpg'),
      ).called(1);
    });

    test('sem previousPath, não tenta apagar nada', () async {
      await service.replace(
        bucket: 'avatars',
        folder: 'user-1',
        bytes: _bytes(),
        originalFileName: 'foto.jpg',
        contentType: 'image/jpeg',
        config: _config,
      );

      verifyNever(
        () => repository.delete(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
        ),
      );
    });

    test('falha ao apagar o arquivo anterior não derruba a operação '
        '(best-effort)', () async {
      when(
        () => repository.delete(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
        ),
      ).thenThrow(const StorageException('Falha de rede.'));

      await expectLater(
        service.replace(
          bucket: 'avatars',
          folder: 'user-1',
          bytes: _bytes(),
          originalFileName: 'foto.jpg',
          contentType: 'image/jpeg',
          config: _config,
          previousPath: 'user-1/old.jpg',
        ),
        completes,
      );
    });

    test('upload que falha nunca chama delete do arquivo anterior', () async {
      expect(
        () => service.replace(
          bucket: 'avatars',
          folder: 'user-1',
          bytes: _bytes(11),
          originalFileName: 'foto.jpg',
          contentType: 'image/jpeg',
          config: _config,
          previousPath: 'user-1/old.jpg',
        ),
        throwsA(isA<StorageException>()),
      );
      verifyNever(
        () => repository.delete(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
        ),
      );
    });
  });

  group('download()/delete()/getPublicUrl()/createSignedUrl()', () {
    test('download() delega ao repositório', () async {
      final bytes = _bytes();
      when(
        () => repository.download(bucket: 'avatars', path: 'user-1/a.jpg'),
      ).thenAnswer((_) async => bytes);

      final result = await service.download(
        bucket: 'avatars',
        path: 'user-1/a.jpg',
      );

      expect(result, bytes);
    });

    test('delete() delega ao repositório', () async {
      when(
        () => repository.delete(bucket: 'avatars', path: 'user-1/a.jpg'),
      ).thenAnswer((_) async {});

      await service.delete(bucket: 'avatars', path: 'user-1/a.jpg');

      verify(
        () => repository.delete(bucket: 'avatars', path: 'user-1/a.jpg'),
      ).called(1);
    });

    test('getPublicUrl() delega ao repositório', () {
      when(
        () => repository.getPublicUrl(
          bucket: 'restaurants',
          path: 'r-1/cover.jpg',
        ),
      ).thenReturn('https://example.com/r-1/cover.jpg');

      final url = service.getPublicUrl(
        bucket: 'restaurants',
        path: 'r-1/cover.jpg',
      );

      expect(url, 'https://example.com/r-1/cover.jpg');
    });

    test('createSignedUrl() delega ao repositório com expiração padrão de '
        '3600s', () async {
      when(
        () => repository.createSignedUrl(
          bucket: 'avatars',
          path: 'user-1/a.jpg',
          expiresInSeconds: 3600,
        ),
      ).thenAnswer((_) async => 'https://example.com/signed');

      final url = await service.createSignedUrl(
        bucket: 'avatars',
        path: 'user-1/a.jpg',
      );

      expect(url, 'https://example.com/signed');
    });

    test('propaga StorageException do repositório', () async {
      when(
        () => repository.download(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
        ),
      ).thenThrow(const StorageException('Arquivo não encontrado.'));

      await expectLater(
        service.download(bucket: 'avatars', path: 'user-1/a.jpg'),
        throwsA(isA<StorageException>()),
      );
    });
  });
}
