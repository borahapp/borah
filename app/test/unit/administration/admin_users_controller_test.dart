import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/administration/application/admin_users_controller.dart';
import 'package:app/features/administration/presentation/states/admin_users_status.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

UserProfile _profile({String id = 'user-1'}) {
  return UserProfile(
    id: id,
    fullName: 'Ana',
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockUserProfileRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockUserProfileRepository();
    container = ProviderContainer(
      overrides: [userProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é AdminUsersInitial', () {
    expect(
      container.read(adminUsersControllerProvider),
      isA<AdminUsersInitial>(),
    );
  });

  test('load com resultados -> AdminUsersLoaded', () async {
    when(() => repository.listAll(query: null, page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(adminUsersControllerProvider.notifier).load();

    expect(
      container.read(adminUsersControllerProvider),
      isA<AdminUsersLoaded>(),
    );
  });

  test('load sem resultados -> AdminUsersEmpty', () async {
    when(() => repository.listAll(query: null, page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(adminUsersControllerProvider.notifier).load();

    expect(
      container.read(adminUsersControllerProvider),
      isA<AdminUsersEmpty>(),
    );
  });

  test('load com falha -> AdminUsersError', () async {
    when(
      () => repository.listAll(query: null, page: 1, limit: 20),
    ).thenThrow(const UserProfileRepositoryException('Falha.'));

    await container.read(adminUsersControllerProvider.notifier).load();

    expect(
      container.read(adminUsersControllerProvider),
      isA<AdminUsersError>(),
    );
  });

  test('loadNextPage concatena os itens da nova página aos já carregados em '
      'vez de substituir a lista', () async {
    when(() => repository.listAll(query: null, page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(() => repository.listAll(query: null, page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(adminUsersControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(adminUsersControllerProvider);
    expect(status, isA<AdminUsersLoaded>());
    expect((status as AdminUsersLoaded).result.items.map((u) => u.id), [
      'user-1',
      'user-2',
    ]);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar AdminUsersError', () async {
    when(() => repository.listAll(query: null, page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listAll(query: null, page: 2, limit: 20),
    ).thenThrow(const UserProfileRepositoryException('Falha de rede.'));

    final notifier = container.read(adminUsersControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(adminUsersControllerProvider);
    expect(status, isA<AdminUsersLoaded>());
    expect((status as AdminUsersLoaded).result.items.map((u) => u.id), [
      'user-1',
    ]);
  });

  test('após falha em loadNextPage, uma nova tentativa rebusca a MESMA '
      'página em vez de pular para a seguinte', () async {
    when(() => repository.listAll(query: null, page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listAll(query: null, page: 2, limit: 20),
    ).thenThrow(const UserProfileRepositoryException('Falha de rede.'));

    final notifier = container.read(adminUsersControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage(); // página 2 falha

    expect(
      (container.read(adminUsersControllerProvider) as AdminUsersLoaded)
          .result
          .items
          .map((u) => u.id),
      ['user-1'],
    );

    // A segunda tentativa deve rebuscar a página 2 (a que falhou), nunca
    // pular direto para a 3.
    when(() => repository.listAll(query: null, page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );
    await notifier.loadNextPage();

    final finalStatus = container.read(adminUsersControllerProvider);
    expect(finalStatus, isA<AdminUsersLoaded>());
    expect((finalStatus as AdminUsersLoaded).result.items.map((u) => u.id), [
      'user-1',
      'user-2',
    ]);
    verifyNever(() => repository.listAll(query: null, page: 3, limit: 20));
  });

  test('concorrência entre loadNextPage e um novo load (busca aplicada): a '
      'resposta desatualizada do loadNextPage não sobrescreve o resultado '
      'mais recente', () async {
    when(() => repository.listAll(query: null, page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(adminUsersControllerProvider.notifier);
    await notifier.load();

    // loadNextPage (página 2) fica pendente, controlado manualmente.
    final page2Completer = Completer<PagedResult<UserProfile>>();
    when(
      () => repository.listAll(query: null, page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, o usuário busca por nome - um novo load mais
    // recente é disparado.
    when(() => repository.listAll(query: 'Ana', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_profile(id: 'user-9')],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final loadOtherFuture = notifier.load(query: 'Ana');

    // A resposta da página 2 sem busca chega DEPOIS do novo load já ter
    // assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [_profile(id: 'user-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await loadNextPageFuture;
    await loadOtherFuture;

    final status = container.read(adminUsersControllerProvider);
    expect(status, isA<AdminUsersLoaded>());
    final items = (status as AdminUsersLoaded).result.items;
    expect(items.map((u) => u.id), ['user-9']);
  });
}
