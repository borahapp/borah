import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/administration/application/admin_roles_controller.dart';
import 'package:app/features/administration/data/admin_role_repository_impl.dart';
import 'package:app/features/administration/data/audit_log_repository_impl.dart';
import 'package:app/features/administration/domain/admin_role_repository.dart';
import 'package:app/features/administration/domain/audit_log_repository.dart';
import 'package:app/features/administration/presentation/states/admin_roles_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRoleRepository extends Mock implements AdminRoleRepository {}

class MockAuditLogRepository extends Mock implements AuditLogRepository {}

void main() {
  late MockAdminRoleRepository roleRepository;
  late MockAuditLogRepository auditLogRepository;
  late ProviderContainer container;

  setUp(() {
    roleRepository = MockAdminRoleRepository();
    auditLogRepository = MockAuditLogRepository();
    container = ProviderContainer(
      overrides: [
        adminRoleRepositoryProvider.overrideWithValue(roleRepository),
        auditLogRepositoryProvider.overrideWithValue(auditLogRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é AdminRolesInitial', () {
    expect(
      container.read(adminRolesControllerProvider),
      isA<AdminRolesInitial>(),
    );
  });

  test('load com resultados -> AdminRolesLoaded', () async {
    when(() => roleRepository.listAdmins(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-1',
            role: 'moderator',
            fullName: 'Ana',
          ),
        ],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(adminRolesControllerProvider.notifier).load();

    expect(
      container.read(adminRolesControllerProvider),
      isA<AdminRolesLoaded>(),
    );
  });

  test('grantRole concede papel e registra auditoria', () async {
    when(() => roleRepository.listAdmins(page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    when(
      () => roleRepository.grantRole('user-1', 'moderator'),
    ).thenAnswer((_) async {});
    when(
      () => auditLogRepository.log(
        actorId: any(named: 'actorId'),
        action: any(named: 'action'),
        entity: any(named: 'entity'),
        entityId: any(named: 'entityId'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});

    final notifier = container.read(adminRolesControllerProvider.notifier);
    await notifier.load();
    await notifier.grantRole('user-1', 'moderator', actorId: 'super-1');

    verify(() => roleRepository.grantRole('user-1', 'moderator')).called(1);
    verify(
      () => auditLogRepository.log(
        actorId: 'super-1',
        action: 'grant_admin_role',
        entity: 'user',
        entityId: 'user-1',
        metadata: {'role': 'moderator'},
      ),
    ).called(1);
  });

  test('grantRole sem permissão -> AdminRolesError', () async {
    when(() => roleRepository.listAdmins(page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    when(
      () => roleRepository.grantRole('user-1', 'moderator'),
    ).thenThrow(const AdminRoleRepositoryException('Permissão insuficiente.'));

    final notifier = container.read(adminRolesControllerProvider.notifier);
    await notifier.load();
    await notifier.grantRole('user-1', 'moderator', actorId: 'user-2');

    expect(
      container.read(adminRolesControllerProvider),
      isA<AdminRolesError>(),
    );
  });

  test('loadNextPage concatena os itens da nova página aos já carregados em '
      'vez de substituir a lista', () async {
    when(() => roleRepository.listAdmins(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-1',
            role: 'moderator',
            fullName: 'Ana',
          ),
        ],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(() => roleRepository.listAdmins(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-2',
            role: 'admin',
            fullName: 'Bia',
          ),
        ],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(adminRolesControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(adminRolesControllerProvider);
    expect(status, isA<AdminRolesLoaded>());
    expect((status as AdminRolesLoaded).result.items.map((e) => e.userId), [
      'user-1',
      'user-2',
    ]);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar AdminRolesError', () async {
    when(() => roleRepository.listAdmins(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-1',
            role: 'moderator',
            fullName: 'Ana',
          ),
        ],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => roleRepository.listAdmins(page: 2, limit: 20),
    ).thenThrow(const AdminRoleRepositoryException('Falha de rede.'));

    final notifier = container.read(adminRolesControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(adminRolesControllerProvider);
    expect(status, isA<AdminRolesLoaded>());
    expect((status as AdminRolesLoaded).result.items.map((e) => e.userId), [
      'user-1',
    ]);
  });

  test('após falha em loadNextPage, uma nova tentativa rebusca a MESMA '
      'página em vez de pular para a seguinte', () async {
    when(() => roleRepository.listAdmins(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-1',
            role: 'moderator',
            fullName: 'Ana',
          ),
        ],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => roleRepository.listAdmins(page: 2, limit: 20),
    ).thenThrow(const AdminRoleRepositoryException('Falha de rede.'));

    final notifier = container.read(adminRolesControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage(); // página 2 falha

    expect(
      (container.read(adminRolesControllerProvider) as AdminRolesLoaded)
          .result
          .items
          .map((e) => e.userId),
      ['user-1'],
    );

    // A segunda tentativa deve rebuscar a página 2 (a que falhou), nunca
    // pular direto para a 3.
    when(() => roleRepository.listAdmins(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-2',
            role: 'admin',
            fullName: 'Bia',
          ),
        ],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );
    await notifier.loadNextPage();

    final finalStatus = container.read(adminRolesControllerProvider);
    expect(finalStatus, isA<AdminRolesLoaded>());
    expect(
      (finalStatus as AdminRolesLoaded).result.items.map((e) => e.userId),
      ['user-1', 'user-2'],
    );
    verifyNever(() => roleRepository.listAdmins(page: 3, limit: 20));
  });

  test('concorrência entre loadNextPage e grantRole: a resposta '
      'desatualizada do loadNextPage não sobrescreve o resultado mais '
      'recente da mutação', () async {
    when(() => roleRepository.listAdmins(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-1',
            role: 'moderator',
            fullName: 'Ana',
          ),
        ],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(adminRolesControllerProvider.notifier);
    await notifier.load();

    // loadNextPage (página 2) fica pendente, controlado manualmente.
    final page2Completer = Completer<PagedResult<AdminRoleEntry>>();
    when(
      () => roleRepository.listAdmins(page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, um novo papel é concedido - grantRole reseta para
    // a página 1 com o dado já atualizado.
    when(
      () => roleRepository.grantRole('user-3', 'admin'),
    ).thenAnswer((_) async {});
    when(
      () => auditLogRepository.log(
        actorId: any(named: 'actorId'),
        action: any(named: 'action'),
        entity: any(named: 'entity'),
        entityId: any(named: 'entityId'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});
    when(() => roleRepository.listAdmins(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-1',
            role: 'moderator',
            fullName: 'Ana',
          ),
          const AdminRoleEntry(
            userId: 'user-3',
            role: 'admin',
            fullName: 'Carla',
          ),
        ],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final grantRoleFuture = notifier.grantRole(
      'user-3',
      'admin',
      actorId: 'super-1',
    );

    // A resposta da página 2 (mais antiga) chega DEPOIS de grantRole já
    // ter assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [
          const AdminRoleEntry(
            userId: 'user-2',
            role: 'admin',
            fullName: 'Bia',
          ),
        ],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await loadNextPageFuture;
    await grantRoleFuture;

    final status = container.read(adminRolesControllerProvider);
    expect(status, isA<AdminRolesLoaded>());
    final items = (status as AdminRolesLoaded).result.items;
    expect(items.map((e) => e.userId), ['user-1', 'user-3']);
  });
}
