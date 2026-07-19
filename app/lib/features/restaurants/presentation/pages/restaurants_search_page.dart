import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../application/restaurants_controller.dart';
import '../states/restaurants_status.dart';

/// Tela de Pesquisa (UX-02 §8), combinando busca + filtros + listagem em
/// uma única tela — o wireframe já une esses três itens do DV-03 §6.
class RestaurantsSearchPage extends ConsumerStatefulWidget {
  const RestaurantsSearchPage({super.key});

  @override
  ConsumerState<RestaurantsSearchPage> createState() =>
      _RestaurantsSearchPageState();
}

class _RestaurantsSearchPageState extends ConsumerState<RestaurantsSearchPage> {
  final _queryController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restaurantsControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(restaurantsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar restaurante',
            onPressed: () => context.push('/restaurants/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppTextField(
                  controller: _queryController,
                  label: 'Buscar por nome',
                  onSubmit: (value) => ref
                      .read(restaurantsControllerProvider.notifier)
                      .search(value ?? ''),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _cityController,
                  label: 'Filtrar por cidade',
                  onSubmit: (value) => ref
                      .read(restaurantsControllerProvider.notifier)
                      .applyFilters(city: value),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (status) {
              RestaurantsInitial() || RestaurantsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              RestaurantsSearching() || RestaurantsFiltering() => const Center(
                child: CircularProgressIndicator(),
              ),
              RestaurantsError(:final message) => Center(child: Text(message)),
              RestaurantsEmpty() => const Center(
                child: Text('Nenhum restaurante encontrado.'),
              ),
              RestaurantsLoaded(:final result) => ListView.builder(
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final restaurant = result.items[index];
                  return ListTile(
                    title: Text(restaurant.name),
                    subtitle: Text(
                      [
                        restaurant.category,
                        if (restaurant.city != null) restaurant.city,
                      ].join(' · '),
                    ),
                    trailing: restaurant.averageRating != null
                        ? Text(restaurant.averageRating!.toStringAsFixed(1))
                        : null,
                    onTap: () => context.push('/restaurants/${restaurant.id}'),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}
