import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/administration/application/audit_log_controller.dart';
import 'package:app/features/administration/data/audit_log_repository_impl.dart';
import 'package:app/features/administration/domain/audit_log_entry.dart';
import 'package:app/features/administration/domain/audit_log_repository.dart';
import 'package:app/features/administration/presentation/states/audit_log_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuditLogRepository extends Mock implements AuditLogRepository {}

AuditLogEntry _entry({String id = 'log-1'}) {
  return AuditLogEntry(
    id: id,
    actorId: 'admin-1',
    action: 'hide_comment',
    entity: 'comment',
    entityId: 'c-1',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockAuditLogRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockAuditLogRepository();
    container = ProviderContainer(
      overrides: [auditLogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é AuditLogInitial', () {
    expect(container.read(auditLogControllerProvider), isA<AuditLogInitial>());
  });

  test('load com resultados -> AuditLogLoaded', () async {
    when(() => repository.listRecent(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(auditLogControllerProvider.notifier).load();

    expect(container.read(auditLogControllerProvider), isA<AuditLogLoaded>());
  });

  test('load sem resultados -> AuditLogEmpty', () async {
    when(() => repository.listRecent(page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container.read(auditLogControllerProvider.notifier).load();

    expect(container.read(auditLogControllerProvider), isA<AuditLogEmpty>());
  });

  test('load com falha -> AuditLogError', () async {
    when(
      () => repository.listRecent(page: 1, limit: 20),
    ).thenThrow(const AuditLogRepositoryException('Falha.'));

    await container.read(auditLogControllerProvider.notifier).load();

    expect(container.read(auditLogControllerProvider), isA<AuditLogError>());
  });

  test('loadNextPage concatena os itens da nova página aos já carregados em '
      'vez de substituir a lista', () async {
    when(() => repository.listRecent(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(id: 'log-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(() => repository.listRecent(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(id: 'log-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(auditLogControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(auditLogControllerProvider);
    expect(status, isA<AuditLogLoaded>());
    expect((status as AuditLogLoaded).result.items.map((e) => e.id), [
      'log-1',
      'log-2',
    ]);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar AuditLogError', () async {
    when(() => repository.listRecent(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(id: 'log-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listRecent(page: 2, limit: 20),
    ).thenThrow(const AuditLogRepositoryException('Falha de rede.'));

    final notifier = container.read(auditLogControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(auditLogControllerProvider);
    expect(status, isA<AuditLogLoaded>());
    expect((status as AuditLogLoaded).result.items.map((e) => e.id), ['log-1']);
  });

  test('concorrência entre loadNextPage e um novo load: a resposta '
      'desatualizada do loadNextPage não sobrescreve o resultado mais '
      'recente', () async {
    when(() => repository.listRecent(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(id: 'log-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(auditLogControllerProvider.notifier);
    await notifier.load();

    // loadNextPage (página 2) fica pendente, controlado manualmente.
    final page2Completer = Completer<PagedResult<AuditLogEntry>>();
    when(
      () => repository.listRecent(page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, um novo load mais recente é disparado (ex.:
    // reabrir a tela).
    when(() => repository.listRecent(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_entry(id: 'log-9')],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final loadOtherFuture = notifier.load();

    // A resposta da página 2 anterior chega DEPOIS do novo load já ter
    // assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [_entry(id: 'log-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await loadNextPageFuture;
    await loadOtherFuture;

    final status = container.read(auditLogControllerProvider);
    expect(status, isA<AuditLogLoaded>());
    final items = (status as AuditLogLoaded).result.items;
    expect(items.map((e) => e.id), ['log-9']);
  });
}
