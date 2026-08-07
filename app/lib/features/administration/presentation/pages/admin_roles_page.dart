import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
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
  final _scrollController = ScrollController();
  String _selectedRole = _availableRoles.first;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminRolesControllerProvider.notifier).load();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _userIdController.dispose();
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
    ref.read(adminRolesControllerProvider.notifier).loadNextPage().whenComplete(
      () {
        if (mounted) _isLoadingMore = false;
      },
    );
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
        appBar: const AppTopBar(title: 'Papéis administrativos'),
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
                AdminRolesInitial() ||
                AdminRolesLoading() => const LoadingScreen(),
                AdminRolesError(:final message) => ErrorState(
                  message: message,
                  onRetry: () =>
                      ref.read(adminRolesControllerProvider.notifier).load(),
                ),
                AdminRolesEmpty() => const EmptyState(
                  message: 'Nenhum administrador cadastrado.',
                ),
                AdminRolesSaving(:final result) ||
                AdminRolesLoaded(:final result) => ListView.builder(
                  controller: _scrollController,
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final entry = result.items[index];
                    return ListTile(
                      title: Text(entry.fullName ?? entry.userId),
                      subtitle: Text(entry.role),
                      trailing: AppTextButton(
                        label: 'Revogar',
                        onPressed: () => _revoke(entry.userId),
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
