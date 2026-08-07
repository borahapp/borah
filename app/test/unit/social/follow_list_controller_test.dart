import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/social/application/follow_list_controller.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/social/presentation/states/follow_list_status.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRepository extends Mock implements FollowerRepository {}

UserProfile _profile({String id = 'user-2'}) {
  return UserProfile(
    id: id,
    fullName: 'Maria',
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockFollowerRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFollowerRepository();
    container = ProviderContainer(
      overrides: [followerRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FollowListInitial', () {
    expect(
      container.read(followListControllerProvider),
      isA<FollowListInitial>(),
    );
  });

  test('load(followers) com resultados -> FollowListLoaded', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(followListControllerProvider.notifier)
        .load('user-1', FollowListType.followers);

    expect(
      container.read(followListControllerProvider),
      isA<FollowListLoaded>(),
    );
    verify(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).called(1);
  });

  test('load(following) chama listFollowing', () async {
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(followListControllerProvider.notifier)
        .load('user-1', FollowListType.following);

    verify(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).called(1);
  });

  test('sem resultados -> FollowListEmpty', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(followListControllerProvider.notifier)
        .load('user-1', FollowListType.followers);

    expect(
      container.read(followListControllerProvider),
      isA<FollowListEmpty>(),
    );
  });

  test('com falha -> FollowListError', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenThrow(const FollowerRepositoryException('Falha ao carregar.'));

    await container
        .read(followListControllerProvider.notifier)
        .load('user-1', FollowListType.followers);

    expect(
      container.read(followListControllerProvider),
      isA<FollowListError>(),
    );
  });

  test('loadNextPage concatena os itens da nova página aos já carregados em '
      'vez de substituir a lista', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-2')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listFollowers('user-1', page: 2, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-3')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(followListControllerProvider.notifier);
    await notifier.load('user-1', FollowListType.followers);
    await notifier.loadNextPage();

    final status = container.read(followListControllerProvider);
    expect(status, isA<FollowListLoaded>());
    expect((status as FollowListLoaded).result.items.map((u) => u.id), [
      'user-2',
      'user-3',
    ]);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar FollowListError', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-2')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listFollowers('user-1', page: 2, limit: 20),
    ).thenThrow(const FollowerRepositoryException('Falha de rede.'));

    final notifier = container.read(followListControllerProvider.notifier);
    await notifier.load('user-1', FollowListType.followers);
    await notifier.loadNextPage();

    final status = container.read(followListControllerProvider);
    expect(status, isA<FollowListLoaded>());
    expect((status as FollowListLoaded).result.items.map((u) => u.id), [
      'user-2',
    ]);
  });

  test('concorrência entre loadNextPage e um novo load (troca de tipo): a '
      'resposta desatualizada do loadNextPage não sobrescreve o resultado '
      'mais recente', () async {
    when(
      () => repository.listFollowers('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-2')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(followListControllerProvider.notifier);
    await notifier.load('user-1', FollowListType.followers);

    // loadNextPage (página 2 de seguidores) fica pendente, controlado
    // manualmente.
    final page2Completer = Completer<PagedResult<UserProfile>>();
    when(
      () => repository.listFollowers('user-1', page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, o usuário troca para "Seguindo" - um novo load
    // mais recente é disparado.
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-9')],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final loadOtherFuture = notifier.load('user-1', FollowListType.following);

    // A resposta da página 2 de seguidores chega DEPOIS do novo load já
    // ter assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [_profile(id: 'user-3')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await loadNextPageFuture;
    await loadOtherFuture;

    final status = container.read(followListControllerProvider);
    expect(status, isA<FollowListLoaded>());
    final items = (status as FollowListLoaded).result.items;
    expect(items.map((u) => u.id), ['user-9']);
  });
}
