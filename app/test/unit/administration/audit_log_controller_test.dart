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
}
