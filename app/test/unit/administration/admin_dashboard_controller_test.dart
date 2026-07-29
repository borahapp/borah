import 'package:app/features/administration/application/admin_dashboard_controller.dart';
import 'package:app/features/administration/data/dashboard_repository_impl.dart';
import 'package:app/features/administration/domain/dashboard_kpis.dart';
import 'package:app/features/administration/domain/dashboard_repository.dart';
import 'package:app/features/administration/presentation/states/dashboard_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockDashboardRepository();
    container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é DashboardInitial', () {
    expect(
      container.read(adminDashboardControllerProvider),
      isA<DashboardInitial>(),
    );
  });

  test('load sucesso -> DashboardLoaded', () async {
    when(() => repository.getKpis()).thenAnswer(
      (_) async => const DashboardKpis(
        usersCount: 10,
        restaurantsCount: 5,
        reviewsCount: 20,
        pendingReportsCount: 2,
      ),
    );

    await container.read(adminDashboardControllerProvider.notifier).load();

    final status = container.read(adminDashboardControllerProvider);
    expect(status, isA<DashboardLoaded>());
    expect((status as DashboardLoaded).kpis.usersCount, 10);
  });

  test('load falha -> DashboardError', () async {
    when(
      () => repository.getKpis(),
    ).thenThrow(const DashboardRepositoryException('Falha.'));

    await container.read(adminDashboardControllerProvider.notifier).load();

    expect(
      container.read(adminDashboardControllerProvider),
      isA<DashboardError>(),
    );
  });
}
