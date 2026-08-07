import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../application/audit_log_controller.dart';
import '../states/audit_log_status.dart';
import '../widgets/admin_guard.dart';

/// Consulta de Auditoria (DV-08 §7), somente leitura - a tabela é
/// append-only.
class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditLogControllerProvider.notifier).load();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _isLoadingMore = true;
    ref.read(auditLogControllerProvider.notifier).loadNextPage().whenComplete(
      () {
        if (mounted) _isLoadingMore = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(auditLogControllerProvider);

    return AdminGuard(
      child: Scaffold(
        appBar: const AppTopBar(title: 'Auditoria'),
        body: switch (status) {
          AuditLogInitial() || AuditLogLoading() => const LoadingScreen(),
          AuditLogError(:final message) => ErrorState(
            message: message,
            onRetry: () => ref.read(auditLogControllerProvider.notifier).load(),
          ),
          AuditLogEmpty() => const EmptyState(
            message: 'Nenhum registro de auditoria ainda.',
          ),
          AuditLogLoaded(:final result) => ListView.builder(
            controller: _scrollController,
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final entry = result.items[index];
              return ListTile(
                title: Text(entry.action),
                subtitle: Text('${entry.entity} · ${entry.entityId}'),
                trailing: Text(
                  '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
