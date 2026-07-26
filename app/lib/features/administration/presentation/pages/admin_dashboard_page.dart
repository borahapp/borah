import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../application/admin_dashboard_controller.dart';
import '../states/dashboard_status.dart';
import '../widgets/admin_guard.dart';

/// Dashboard (DV-08 §6/§7) - KPIs simples. "Relatórios" foi dobrado aqui
/// (mesmas contagens), sem tela separada (decisão da análise do DV-08).
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminDashboardControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adminDashboardControllerProvider);

    return AdminGuard(
      child: Scaffold(
        appBar: const AppTopBar(title: 'Administração'),
        body: switch (status) {
          DashboardInitial() || DashboardLoading() => const LoadingScreen(),
          DashboardError(:final message) => ErrorState(
            message: message,
            onRetry: () =>
                ref.read(adminDashboardControllerProvider.notifier).load(),
          ),
          DashboardLoaded(:final kpis) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: 'Usuários',
                        value: kpis.usersCount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        label: 'Restaurantes',
                        value: kpis.restaurantsCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: 'Avaliações',
                        value: kpis.reviewsCount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        label: 'Denúncias',
                        value: kpis.pendingReportsCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppOutlinedButton(
                  label: 'Usuários',
                  onPressed: () => context.push('/admin/users'),
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  label: 'Restaurantes',
                  onPressed: () => context.push('/admin/restaurants'),
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  label: 'Moderação',
                  onPressed: () => context.push('/admin/moderation'),
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  label: 'Papéis administrativos',
                  onPressed: () => context.push('/admin/roles'),
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  label: 'Auditoria',
                  onPressed: () => context.push('/admin/audit-logs'),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
