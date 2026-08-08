import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/inputs/app_search_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../application/admin_users_controller.dart';
import '../../application/current_user_role_provider.dart';
import '../states/admin_users_status.dart';
import '../widgets/admin_guard.dart';

/// Gestão de Usuários (DV-08 §6): apenas "Consultar". "Visualizar
/// histórico" é a própria tela de Perfil público (DV-07), que já lista as
/// avaliações do usuário. "Bloquear/Reativar" fora de escopo.
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfAuthorized());
    _scrollController.addListener(_onScroll);
  }

  /// FASE C.2.1: segunda camada de defesa - sem isto, a carga inicial
  /// disparava antes de `AdminGuard` confirmar o papel do usuário (a RLS
  /// já protegia os dados, mas a consulta saía do cliente de qualquer
  /// forma). Reaproveita o mesmo `Future` que `AdminGuard` já observa
  /// (`currentUserRoleProvider` não é `autoDispose` - não gera uma
  /// segunda consulta de papel).
  Future<void> _loadIfAuthorized() async {
    final String? role;
    try {
      role = await ref.read(currentUserRoleProvider.future);
    } catch (_) {
      return;
    }
    if (!mounted || role == null) return;
    ref.read(adminUsersControllerProvider.notifier).load();
  }

  @override
  void dispose() {
    _queryController.dispose();
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
    ref.read(adminUsersControllerProvider.notifier).loadNextPage().whenComplete(
      () {
        if (mounted) _isLoadingMore = false;
      },
    );
  }

  void _search() {
    ref
        .read(adminUsersControllerProvider.notifier)
        .load(query: _queryController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adminUsersControllerProvider);

    return AdminGuard(
      child: Scaffold(
        appBar: const AppTopBar(title: 'Usuários'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppSearchField(
                controller: _queryController,
                label: 'Buscar por nome',
                onSubmit: (_) => _search(),
              ),
            ),
            Expanded(
              child: switch (status) {
                AdminUsersInitial() ||
                AdminUsersLoading() => const LoadingScreen(),
                AdminUsersError(:final message) => ErrorState(
                  message: message,
                  onRetry: () =>
                      ref.read(adminUsersControllerProvider.notifier).load(),
                ),
                AdminUsersEmpty() => const EmptyState(
                  message: 'Nenhum usuário encontrado.',
                ),
                AdminUsersLoaded(:final result) => ListView.builder(
                  controller: _scrollController,
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final profile = result.items[index];
                    return ListTile(
                      title: Text(profile.fullName ?? ''),
                      subtitle: profile.city != null
                          ? Text(profile.city!)
                          : null,
                      onTap: () => context.push('/users/${profile.id}'),
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
