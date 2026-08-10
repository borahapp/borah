import 'package:app/core/models/paged_result.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/search/application/featured_groups_controller.dart';
import 'package:app/features/search/presentation/states/featured_groups_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

Group _group(String id) {
  return Group(
    id: id,
    name: 'Grupo $id',
    description: null,
    photoUrl: null,
    inviteCode: 'ABCDEFGH',
    visibility: 'public',
    memberCount: 1,
  );
}

void main() {
  late MockGroupRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockGroupRepository();
    container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FeaturedGroupsInitial', () {
    expect(
      container.read(featuredGroupsControllerProvider),
      isA<FeaturedGroupsInitial>(),
    );
  });

  test('carrega com sucesso', () async {
    when(() => repository.listFeatured(page: 1, limit: 10)).thenAnswer(
      (_) async => PagedResult(
        items: [_group('a'), _group('b')],
        page: 1,
        limit: 10,
        hasNextPage: true,
      ),
    );

    await container.read(featuredGroupsControllerProvider.notifier).load();

    final status = container.read(featuredGroupsControllerProvider);
    expect(status, isA<FeaturedGroupsLoaded>());
    final loaded = status as FeaturedGroupsLoaded;
    expect(loaded.groups, hasLength(2));
    expect(loaded.hasMore, isTrue);
  });

  test('sem grupos -> FeaturedGroupsEmpty', () async {
    when(() => repository.listFeatured(page: 1, limit: 10)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 10, hasNextPage: false),
    );

    await container.read(featuredGroupsControllerProvider.notifier).load();

    expect(
      container.read(featuredGroupsControllerProvider),
      isA<FeaturedGroupsEmpty>(),
    );
  });

  test('erro -> FeaturedGroupsError', () async {
    when(
      () => repository.listFeatured(page: 1, limit: 10),
    ).thenThrow(const GroupRepositoryException('falhou'));

    await container.read(featuredGroupsControllerProvider.notifier).load();

    final status = container.read(featuredGroupsControllerProvider);
    expect(status, isA<FeaturedGroupsError>());
    expect((status as FeaturedGroupsError).message, 'falhou');
  });

  test('loadMore acumula a próxima página', () async {
    when(() => repository.listFeatured(page: 1, limit: 10)).thenAnswer(
      (_) async => PagedResult(
        items: [_group('a')],
        page: 1,
        limit: 10,
        hasNextPage: true,
      ),
    );
    when(() => repository.listFeatured(page: 2, limit: 10)).thenAnswer(
      (_) async => PagedResult(
        items: [_group('b')],
        page: 2,
        limit: 10,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(featuredGroupsControllerProvider.notifier);
    await notifier.load();
    await notifier.loadMore();

    final status = container.read(featuredGroupsControllerProvider);
    expect(status, isA<FeaturedGroupsLoaded>());
    final loaded = status as FeaturedGroupsLoaded;
    expect(loaded.groups.map((g) => g.id), ['a', 'b']);
    expect(loaded.hasMore, isFalse);
  });

  test(
    'loadMore com falha preserva a lista já carregada e reverte a página',
    () async {
      when(() => repository.listFeatured(page: 1, limit: 10)).thenAnswer(
        (_) async => PagedResult(
          items: [_group('a')],
          page: 1,
          limit: 10,
          hasNextPage: true,
        ),
      );
      when(
        () => repository.listFeatured(page: 2, limit: 10),
      ).thenThrow(const GroupRepositoryException('falhou'));
      when(() => repository.listFeatured(page: 3, limit: 10)).thenAnswer(
        (_) async => PagedResult(
          items: [_group('c')],
          page: 3,
          limit: 10,
          hasNextPage: false,
        ),
      );

      final notifier = container.read(
        featuredGroupsControllerProvider.notifier,
      );
      await notifier.load();
      await notifier.loadMore();

      final status = container.read(featuredGroupsControllerProvider);
      expect(status, isA<FeaturedGroupsLoaded>());
      expect((status as FeaturedGroupsLoaded).groups.map((g) => g.id), ['a']);

      // A página que falhou (2) é retentada, não pulada para a 3.
      await notifier.loadMore();
      verify(() => repository.listFeatured(page: 2, limit: 10)).called(2);
    },
  );
}
