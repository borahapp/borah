import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/admin_restaurants_controller.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminRestaurantsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
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
        appBar: AppBar(title: const Text('Restaurantes')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _queryController,
                label: 'Buscar por nome',
                onSubmit: (_) => _search(),
              ),
            ),
            Expanded(
              child: switch (status) {
                AdminRestaurantsInitial() || AdminRestaurantsLoading() =>
                  const Center(child: CircularProgressIndicator()),
                AdminRestaurantsError(:final message) => Center(
                  child: Text(message),
                ),
                AdminRestaurantsEmpty() => const Center(
                  child: Text('Nenhum restaurante encontrado.'),
                ),
                AdminRestaurantsSaving(:final result) ||
                AdminRestaurantsLoaded(:final result) => ListView.builder(
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final restaurant = result.items[index];
                    return ListTile(
                      title: Text(restaurant.name),
                      subtitle: Text(restaurant.status),
                      trailing: TextButton(
                        onPressed: () =>
                            _toggleStatus(restaurant.id, restaurant.status),
                        child: Text(
                          restaurant.status == 'active'
                              ? 'Arquivar'
                              : 'Reativar',
                        ),
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
