import 'dart:typed_data';

import 'package:app/core/storage/app_storage.dart';
import 'package:app/core/storage/storage_exception.dart';
import 'package:app/core/storage/storage_repository.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/core/storage/storage_upload_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late MockStorageRepository repository;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockStorageRepository();
    AppStorage.debugServiceOverride = StorageService(repository);
  });

  tearDown(() {
    AppStorage.debugServiceOverride = null;
  });

  test('upload() delega para o serviço e retorna o caminho gerado', () async {
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

    final path = await AppStorage.upload(
      bucket: 'avatars',
      folder: 'user-1',
      bytes: Uint8List(5),
      originalFileName: 'foto.jpg',
      contentType: 'image/jpeg',
      config: StorageUploadConfig.avatar,
    );

    expect(path, startsWith('user-1/'));
    expect(path, endsWith('.jpg'));
  });

  test('upload() propaga StorageException de validação (arquivo grande '
      'demais)', () async {
    final oversized = Uint8List(StorageUploadConfig.avatar.maxBytes + 1);

    await expectLater(
      AppStorage.upload(
        bucket: 'avatars',
        folder: 'user-1',
        bytes: oversized,
        originalFileName: 'foto.jpg',
        contentType: 'image/jpeg',
        config: StorageUploadConfig.avatar,
      ),
      throwsA(isA<StorageException>()),
    );
  });

  test('delete() delega para o serviço', () async {
    when(
      () => repository.delete(bucket: 'avatars', path: 'user-1/a.jpg'),
    ).thenAnswer((_) async {});

    await AppStorage.delete(bucket: 'avatars', path: 'user-1/a.jpg');

    verify(
      () => repository.delete(bucket: 'avatars', path: 'user-1/a.jpg'),
    ).called(1);
  });

  test('replace() faz upload e apaga o arquivo anterior', () async {
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
    when(
      () => repository.delete(
        bucket: any(named: 'bucket'),
        path: any(named: 'path'),
      ),
    ).thenAnswer((_) async {});

    await AppStorage.replace(
      bucket: 'avatars',
      folder: 'user-1',
      bytes: Uint8List(5),
      originalFileName: 'foto.jpg',
      contentType: 'image/jpeg',
      config: StorageUploadConfig.avatar,
      previousPath: 'user-1/old.jpg',
    );

    verify(
      () => repository.delete(bucket: 'avatars', path: 'user-1/old.jpg'),
    ).called(1);
  });

  test('getPublicUrl() delega para o serviço', () {
    when(
      () =>
          repository.getPublicUrl(bucket: 'restaurants', path: 'r-1/cover.jpg'),
    ).thenReturn('https://example.com/r-1/cover.jpg');

    final url = AppStorage.getPublicUrl(
      bucket: 'restaurants',
      path: 'r-1/cover.jpg',
    );

    expect(url, 'https://example.com/r-1/cover.jpg');
  });

  test(
    'getSignedUrl() delega para o serviço com expiração padrão de 3600s',
    () async {
      when(
        () => repository.createSignedUrl(
          bucket: 'avatars',
          path: 'user-1/a.jpg',
          expiresInSeconds: 3600,
        ),
      ).thenAnswer((_) async => 'https://example.com/signed');

      final url = await AppStorage.getSignedUrl(
        bucket: 'avatars',
        path: 'user-1/a.jpg',
      );

      expect(url, 'https://example.com/signed');
    },
  );

  test('download() delega para o serviço', () async {
    final bytes = Uint8List(5);
    when(
      () => repository.download(bucket: 'avatars', path: 'user-1/a.jpg'),
    ).thenAnswer((_) async => bytes);

    final result = await AppStorage.download(
      bucket: 'avatars',
      path: 'user-1/a.jpg',
    );

    expect(result, bytes);
  });
}
