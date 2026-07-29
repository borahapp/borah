import '../../domain/dashboard_kpis.dart';

/// Estado do Dashboard (DV-08 §11), sealed class. Prefixo `Dashboard*`
/// para evitar colisão com estados de outros módulos.
sealed class DashboardStatus {
  const DashboardStatus();
}

final class DashboardInitial extends DashboardStatus {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardStatus {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardStatus {
  const DashboardLoaded(this.kpis);

  final DashboardKpis kpis;
}

final class DashboardError extends DashboardStatus {
  const DashboardError(this.message);

  final String message;
}
