import 'package:app/features/search/application/discovery_controller.dart';
import 'package:app/features/search/data/discovery_repository_impl.dart';
import 'package:app/features/search/domain/discovery_repository.dart';
import 'package:app/features/search/presentation/states/discovery_status.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

UserProfile _person(String id) {
  return UserProfile(
    id: id,
    fullName: 'Pessoa $id',
    username: null,
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    followersCount: 0,
    followingCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockDiscoveryRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockDiscoveryRepository();
    container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é DiscoveryInitial', () {
    expect(
      container.read(discoveryControllerProvider),
      isA<DiscoveryInitial>(),
    );
  });

  test('carrega sugestões com sucesso', () async {
    when(() => repository.suggestPeople('user-1', limit: 8)).thenAnswer(
      (_) async => DiscoverySuggestions(
        people: [_person('a'), _person('b')],
        hasMore: true,
      ),
    );

    await container.read(discoveryControllerProvider.notifier).load('user-1');

    final status = container.read(discoveryControllerProvider);
    expect(status, isA<DiscoveryLoaded>());
    final loaded = status as DiscoveryLoaded;
    expect(loaded.people, hasLength(2));
    expect(loaded.hasMore, isTrue);
  });

  test('sem sugestões -> DiscoveryEmpty', () async {
    when(() => repository.suggestPeople('user-1', limit: 8)).thenAnswer(
      (_) async => const DiscoverySuggestions(people: [], hasMore: false),
    );

    await container.read(discoveryControllerProvider.notifier).load('user-1');

    expect(container.read(discoveryControllerProvider), isA<DiscoveryEmpty>());
  });

  test('erro -> DiscoveryError', () async {
    when(
      () => repository.suggestPeople('user-1', limit: 8),
    ).thenThrow(const DiscoveryRepositoryException('falhou'));

    await container.read(discoveryControllerProvider.notifier).load('user-1');

    final status = container.read(discoveryControllerProvider);
    expect(status, isA<DiscoveryError>());
    expect((status as DiscoveryError).message, 'falhou');
  });

  test('loadMore expande o limite e mantém hasMore correto', () async {
    when(() => repository.suggestPeople('user-1', limit: 8)).thenAnswer(
      (_) async => DiscoverySuggestions(
        people: List.generate(8, (i) => _person('p$i')),
        hasMore: true,
      ),
    );
    when(() => repository.suggestPeople('user-1', limit: 16)).thenAnswer(
      (_) async => DiscoverySuggestions(
        people: List.generate(10, (i) => _person('p$i')),
        hasMore: false,
      ),
    );

    final notifier = container.read(discoveryControllerProvider.notifier);
    await notifier.load('user-1');
    final success = await notifier.loadMore('user-1');

    expect(success, isTrue);
    final status = container.read(discoveryControllerProvider);
    expect(status, isA<DiscoveryLoaded>());
    final loaded = status as DiscoveryLoaded;
    expect(loaded.people, hasLength(10));
    expect(loaded.hasMore, isFalse);
  });

  test(
    'loadMore com falha preserva a lista já carregada e retorna false',
    () async {
      when(() => repository.suggestPeople('user-1', limit: 8)).thenAnswer(
        (_) async => DiscoverySuggestions(
          people: List.generate(8, (i) => _person('p$i')),
          hasMore: true,
        ),
      );
      when(
        () => repository.suggestPeople('user-1', limit: 16),
      ).thenThrow(const DiscoveryRepositoryException('falhou'));

      final notifier = container.read(discoveryControllerProvider.notifier);
      await notifier.load('user-1');
      final success = await notifier.loadMore('user-1');

      expect(success, isFalse);
      final status = container.read(discoveryControllerProvider);
      expect(status, isA<DiscoveryLoaded>());
      expect((status as DiscoveryLoaded).people, hasLength(8));
    },
  );

  test('loadMore não faz nada quando hasMore é falso', () async {
    when(() => repository.suggestPeople('user-1', limit: 8)).thenAnswer(
      (_) async => DiscoverySuggestions(people: [_person('a')], hasMore: false),
    );

    final notifier = container.read(discoveryControllerProvider.notifier);
    await notifier.load('user-1');
    await notifier.loadMore('user-1');

    verify(() => repository.suggestPeople('user-1', limit: 8)).called(1);
    verifyNever(() => repository.suggestPeople('user-1', limit: 16));
  });
}
