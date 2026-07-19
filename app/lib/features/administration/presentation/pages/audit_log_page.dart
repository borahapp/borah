import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditLogControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(auditLogControllerProvider);

    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Auditoria')),
        body: switch (status) {
          AuditLogInitial() ||
          AuditLogLoading() => const Center(child: CircularProgressIndicator()),
          AuditLogError(:final message) => Center(child: Text(message)),
          AuditLogEmpty() => const Center(
            child: Text('Nenhum registro de auditoria ainda.'),
          ),
          AuditLogLoaded(:final result) => ListView.builder(
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
