import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/administration/data/admin_role_repository_impl.dart';
import 'package:app/features/administration/domain/admin_role_repository.dart';
import 'package:app/features/administration/presentation/pages/admin_roles_page.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRoleRepository extends Mock implements AdminRoleRepository {}

/// FASE C.2.1 - segunda camada de defesa (ver admin_dashboard_page_test.dart
/// para o racional completo). Nesta tela, `getRole` (checagem de papel do
/// próprio usuário, via `AdminGuard`) e `listAdmins` (dado da tela) vêm do
/// mesmo `adminRoleRepositoryProvider` - um único mock cobre os dois.
Widget _wrap({
  required MockAdminRoleRepository adminRoleRepository,
  String? userId = 'user-1',
}) {
  return ProviderScope(
    overrides: [
      adminRoleRepositoryProvider.overrideWithValue(adminRoleRepository),
      currentUserIdProvider.overrideWithValue(userId),
    ],
    child: const MaterialApp(home: AdminRolesPage()),
  );
}

void main() {
  late MockAdminRoleRepository adminRoleRepository;

  setUp(() {
    adminRoleRepository = MockAdminRoleRepository();
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

      await tester.pumpWidget(_wrap(adminRoleRepository: adminRoleRepository));
      await tester.pump();

      verifyNever(
        () => adminRoleRepository.listAdmins(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      );

      completer.complete(null);
      await tester.pumpAndSettle();

      verifyNever(
        () => adminRoleRepository.listAdmins(
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
    ).thenAnswer((_) async => 'super_admin');
    when(
      () => adminRoleRepository.listAdmins(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(adminRoleRepository: adminRoleRepository));
    await tester.pumpAndSettle();

    verify(
      () => adminRoleRepository.listAdmins(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });
}
