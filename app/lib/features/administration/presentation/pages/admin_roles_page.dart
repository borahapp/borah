import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/admin_roles_controller.dart';
import '../states/admin_roles_status.dart';
import '../widgets/admin_guard.dart';

const _availableRoles = ['super_admin', 'admin', 'moderator', 'support'];

/// Gestão de papéis administrativos (DV-08 - "Alterar permissões").
/// Conceder/revogar só é permitido a `super_admin` - a RLS de
/// `user_roles` que decide isso; um usuário sem esse papel recebe erro
/// ao tentar.
class AdminRolesPage extends ConsumerStatefulWidget {
  const AdminRolesPage({super.key});

  @override
  ConsumerState<AdminRolesPage> createState() => _AdminRolesPageState();
}

class _AdminRolesPageState extends ConsumerState<AdminRolesPage> {
  final _userIdController = TextEditingController();
  String _selectedRole = _availableRoles.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminRolesControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  void _grant() {
    final actorId = ref.read(currentUserIdProvider);
    final userId = _userIdController.text.trim();
    if (actorId == null || userId.isEmpty) return;
    ref
        .read(adminRolesControllerProvider.notifier)
        .grantRole(userId, _selectedRole, actorId: actorId);
    _userIdController.clear();
  }

  void _revoke(String userId) {
    final actorId = ref.read(currentUserIdProvider);
    if (actorId == null) return;
    ref
        .read(adminRolesControllerProvider.notifier)
        .revokeRole(userId, actorId: actorId);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adminRolesControllerProvider);

    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Papéis administrativos')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AppTextField(
                    controller: _userIdController,
                    label: 'ID do usuário',
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: _availableRoles
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(label: 'Conceder papel', onPressed: _grant),
                ],
              ),
            ),
            Expanded(
              child: switch (status) {
                AdminRolesInitial() || AdminRolesLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                AdminRolesError(:final message) => Center(child: Text(message)),
                AdminRolesEmpty() => const Center(
                  child: Text('Nenhum administrador cadastrado.'),
                ),
                AdminRolesSaving(:final result) ||
                AdminRolesLoaded(:final result) => ListView.builder(
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final entry = result.items[index];
                    return ListTile(
                      title: Text(entry.fullName ?? entry.userId),
                      subtitle: Text(entry.role),
                      trailing: TextButton(
                        onPressed: () => _revoke(entry.userId),
                        child: const Text('Revogar'),
                      ),
                    );
                  },
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
