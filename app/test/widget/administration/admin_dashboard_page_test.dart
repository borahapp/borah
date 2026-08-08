import 'dart:async';

import 'package:app/features/administration/data/admin_role_repository_impl.dart';
import 'package:app/features/administration/data/dashboard_repository_impl.dart';
import 'package:app/features/administration/domain/admin_role_repository.dart';
import 'package:app/features/administration/domain/dashboard_kpis.dart';
import 'package:app/features/administration/domain/dashboard_repository.dart';
import 'package:app/features/administration/presentation/pages/admin_dashboard_page.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRoleRepository extends Mock implements AdminRoleRepository {}

class MockDashboardRepository extends Mock implements DashboardRepository {}

/// FASE C.2.1 - segunda camada de defesa: antes desta fase, o
/// `initState` de cada tela administrativa chamava `.load()` do
/// controller direto, sem esperar `AdminGuard`/`currentUserRoleProvider`
/// confirmar o papel do usuário - a RLS de cada tabela já barrava o
/// resultado, mas a consulta saía do cliente de qualquer forma. Este
/// teste comprova que `_loadIfAuthorized` elimina esse disparo prematuro.
Widget _wrap({
  required MockAdminRoleRepository adminRoleRepository,
  required MockDashboardRepository dashboardRepository,
  String? userId = 'user-1',
}) {
  return ProviderScope(
    overrides: [
      adminRoleRepositoryProvider.overrideWithValue(adminRoleRepository),
      dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
      currentUserIdProvider.overrideWithValue(userId),
    ],
    child: const MaterialApp(home: AdminDashboardPage()),
  );
}

void main() {
  late MockAdminRoleRepository adminRoleRepository;
  late MockDashboardRepository dashboardRepository;

  setUp(() {
    adminRoleRepository = MockAdminRoleRepository();
    dashboardRepository = MockDashboardRepository();
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
          dashboardRepository: dashboardRepository,
        ),
      );
      await tester.pump();

      verifyNever(() => dashboardRepository.getKpis());

      completer.complete(null);
      await tester.pumpAndSettle();

      verifyNever(() => dashboardRepository.getKpis());
      expect(find.text('Acesso restrito a administradores.'), findsOneWidget);
    },
  );

  testWidgets('com papel administrativo: a carga inicial continua disparando '
      'normalmente, exatamente uma vez', (tester) async {
    // Viewport padrão do teste é pequeno demais para os 4 `_KpiCard` -
    // mesmo ajuste já usado em settings_page_test.dart para telas com
    // mais conteúdo do que o overflow padrão comporta.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => adminRoleRepository.getRole('user-1'),
    ).thenAnswer((_) async => 'admin');
    when(() => dashboardRepository.getKpis()).thenAnswer(
      (_) async => const DashboardKpis(
        usersCount: 1,
        restaurantsCount: 2,
        reviewsCount: 3,
        pendingReportsCount: 4,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        adminRoleRepository: adminRoleRepository,
        dashboardRepository: dashboardRepository,
      ),
    );
    await tester.pumpAndSettle();

    verify(() => dashboardRepository.getKpis()).called(1);
    expect(find.text('1'), findsOneWidget);
  });
}
