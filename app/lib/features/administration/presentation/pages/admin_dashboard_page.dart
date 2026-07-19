import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        appBar: AppBar(title: const Text('Administração')),
        body: switch (status) {
          DashboardInitial() || DashboardLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          DashboardError(:final message) => Center(child: Text(message)),
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
                OutlinedButton(
                  onPressed: () => context.push('/admin/users'),
                  child: const Text('Usuários'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/admin/restaurants'),
                  child: const Text('Restaurantes'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/admin/moderation'),
                  child: const Text('Moderação'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/admin/roles'),
                  child: const Text('Papéis administrativos'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/admin/audit-logs'),
                  child: const Text('Auditoria'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
