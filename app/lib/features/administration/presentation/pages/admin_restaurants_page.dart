import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/inputs/app_search_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/admin_restaurants_controller.dart';
import '../../application/current_user_role_provider.dart';
import '../states/admin_restaurants_status.dart';
import '../widgets/admin_guard.dart';

/// Gestão de Restaurantes (DV-08 §6): editar (via tela de detalhes já
/// existente), arquivar, reativar. "Aprovar cadastro" e "Gerenciar
/// categorias" fora de escopo (decisão do DV-08).
class AdminRestaurantsPage extends ConsumerStatefulWidget {
  const AdminRestaurantsPage({super.key});

  @override
  ConsumerState<AdminRestaurantsPage> createState() =>
      _AdminRestaurantsPageState();
}

class _AdminRestaurantsPageState extends ConsumerState<AdminRestaurantsPage> {
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
    ref.read(adminRestaurantsControllerProvider.notifier).load();
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
    ref
        .read(adminRestaurantsControllerProvider.notifier)
        .loadNextPage()
        .whenComplete(() {
          if (mounted) _isLoadingMore = false;
        });
  }

  void _search() {
    ref
        .read(adminRestaurantsControllerProvider.notifier)
        .load(query: _queryController.text.trim());
  }

  void _toggleStatus(String restaurantId, String currentStatus) {
    final actorId = ref.read(currentUserIdProvider);
    if (actorId == null) return;
    final newStatus = currentStatus == 'active' ? 'archived' : 'active';
    ref
        .read(adminRestaurantsControllerProvider.notifier)
        .updateStatus(restaurantId, status: newStatus, actorId: actorId);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adminRestaurantsControllerProvider);

    return AdminGuard(
      child: Scaffold(
        appBar: const AppTopBar(title: 'Restaurantes'),
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
                AdminRestaurantsInitial() ||
                AdminRestaurantsLoading() => const LoadingScreen(),
                AdminRestaurantsError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => ref
                      .read(adminRestaurantsControllerProvider.notifier)
                      .load(),
                ),
                AdminRestaurantsEmpty() => const EmptyState(
                  message: 'Nenhum restaurante encontrado.',
                ),
                AdminRestaurantsSaving(:final result) ||
                AdminRestaurantsLoaded(:final result) => ListView.builder(
                  controller: _scrollController,
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final restaurant = result.items[index];
                    final isActive = restaurant.status == 'active';
                    return ListTile(
                      title: Text(restaurant.name),
                      subtitle: Align(
                        alignment: Alignment.centerLeft,
                        child: AppBadge(
                          label: isActive ? 'Ativo' : 'Arquivado',
                          earned: isActive,
                        ),
                      ),
                      trailing: AppTextButton(
                        label: isActive ? 'Arquivar' : 'Reativar',
                        onPressed: () =>
                            _toggleStatus(restaurant.id, restaurant.status),
                      ),
                      onTap: () =>
                          context.push('/restaurants/${restaurant.id}'),
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
