import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../domain/dashboard_kpis.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._datasource);

  final DashboardRemoteDatasource _datasource;

  @override
  Future<DashboardKpis> getKpis() {
    return _guard(() async {
      final results = await Future.wait([
        _datasource.countUsers(),
        _datasource.countRestaurants(),
        _datasource.countReviews(),
        _datasource.countPendingReports(),
      ]);
      return DashboardKpis(
        usersCount: results[0],
        restaurantsCount: results[1],
        reviewsCount: results[2],
        pendingReportsCount: results[3],
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw DashboardRepositoryException(e.message);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardRepositoryImpl(DashboardRemoteDatasource(client));
});
