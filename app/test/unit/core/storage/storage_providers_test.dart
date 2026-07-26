import 'package:app/core/storage/storage_providers.dart';
import 'package:app/core/storage/storage_repository.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late MockStorageRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockStorageRepository();
    container = ProviderContainer(
      overrides: [storageRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('storageServiceProvider constrói um StorageService', () {
    final service = container.read(storageServiceProvider);

    expect(service, isA<StorageService>());
  });

  test('storageServiceProvider usa o storageRepositoryProvider do container '
      '(delega chamadas ao repositório injetado)', () async {
    when(
      () =>
          repository.getPublicUrl(bucket: 'restaurants', path: 'r-1/cover.jpg'),
    ).thenReturn('https://example.com/r-1/cover.jpg');

    final service = container.read(storageServiceProvider);
    final url = service.getPublicUrl(
      bucket: 'restaurants',
      path: 'r-1/cover.jpg',
    );

    expect(url, 'https://example.com/r-1/cover.jpg');
  });

  test('duas leituras do mesmo container retornam a mesma instância de '
      'StorageService (Provider simples, sem estado reativo)', () {
    final first = container.read(storageServiceProvider);
    final second = container.read(storageServiceProvider);

    expect(identical(first, second), isTrue);
  });

  test('propaga chamadas de delete ao repositório injetado', () async {
    when(
      () => repository.delete(
        bucket: any(named: 'bucket'),
        path: any(named: 'path'),
      ),
    ).thenAnswer((_) async {});

    final service = container.read(storageServiceProvider);
    await service.delete(bucket: 'avatars', path: 'user-1/a.jpg');

    verify(
      () => repository.delete(bucket: 'avatars', path: 'user-1/a.jpg'),
    ).called(1);
  });
}
