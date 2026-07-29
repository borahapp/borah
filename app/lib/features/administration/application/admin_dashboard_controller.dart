import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository_impl.dart';
import '../domain/dashboard_repository.dart';
import '../presentation/states/dashboard_status.dart';

class AdminDashboardController extends Notifier<DashboardStatus> {
  @override
  DashboardStatus build() => const DashboardInitial();

  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);

  Future<void> load() async {
    state = const DashboardLoading();
    try {
      final kpis = await _repository.getKpis();
      state = DashboardLoaded(kpis);
    } on DashboardRepositoryException catch (e) {
      state = DashboardError(e.message);
    } catch (_) {
      state = const DashboardError('Não foi possível carregar o dashboard.');
    }
  }
}

final adminDashboardControllerProvider =
    NotifierProvider<AdminDashboardController, DashboardStatus>(
      AdminDashboardController.new,
    );
