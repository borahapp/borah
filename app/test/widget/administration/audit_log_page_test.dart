import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/administration/data/admin_role_repository_impl.dart';
import 'package:app/features/administration/data/audit_log_repository_impl.dart';
import 'package:app/features/administration/domain/admin_role_repository.dart';
import 'package:app/features/administration/domain/audit_log_repository.dart';
import 'package:app/features/administration/presentation/pages/audit_log_page.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRoleRepository extends Mock implements AdminRoleRepository {}

class MockAuditLogRepository extends Mock implements AuditLogRepository {}

/// FASE C.2.1 - segunda camada de defesa (ver admin_dashboard_page_test.dart
/// para o racional completo).
Widget _wrap({
  required MockAdminRoleRepository adminRoleRepository,
  required MockAuditLogRepository auditLogRepository,
  String? userId = 'user-1',
}) {
  return ProviderScope(
    overrides: [
      adminRoleRepositoryProvider.overrideWithValue(adminRoleRepository),
      auditLogRepositoryProvider.overrideWithValue(auditLogRepository),
      currentUserIdProvider.overrideWithValue(userId),
    ],
    child: const MaterialApp(home: AuditLogPage()),
  );
}

void main() {
  late MockAdminRoleRepository adminRoleRepository;
  late MockAuditLogRepository auditLogRepository;

  setUp(() {
    adminRoleRepository = MockAdminRoleRepository();
    auditLogRepository = MockAuditLogRepository();
  });

  testWidgets(
    'sem papel administrativo: a carga inicial nunca é disparada, nem '
    'enquanto o papel ainda está sendo verificado, nem depois de '
    'resolvido como não-admin',
    (tester) async {
      final completer = Completer<String?>();
      when(
        () => adminRoleRepository.getRole('user-1'),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        _wrap(
          adminRoleRepository: adminRoleRepository,
          auditLogRepository: auditLogRepository,
        ),
      );
      await tester.pump();

      verifyNever(
        () => auditLogRepository.listRecent(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      );

      completer.complete(null);
      await tester.pumpAndSettle();

      verifyNever(
        () => auditLogRepository.listRecent(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      );
      expect(find.text('Acesso restrito a administradores.'), findsOneWidget);
    },
  );

  testWidgets('com papel administrativo: a carga inicial continua disparando '
      'normalmente, exatamente uma vez', (tester) async {
    when(
      () => adminRoleRepository.getRole('user-1'),
    ).thenAnswer((_) async => 'support');
    when(
      () => auditLogRepository.listRecent(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(
      _wrap(
        adminRoleRepository: adminRoleRepository,
        auditLogRepository: auditLogRepository,
      ),
    );
    await tester.pumpAndSettle();

    verify(
      () => auditLogRepository.listRecent(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });
}
