import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/feedback/score_bubble.dart';
import '../../../../design_system/components/inputs/app_search_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
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
      appBar: AppTopBar(
        title: 'Restaurantes',
        actions: [
          AppIconButton(
            icon: Icons.add,
            tooltip: 'Adicionar restaurante',
            // F12: busca restaurantes reais (Google Places) antes do
            // cadastro manual - `/restaurants/new` continua existindo
            // como alternativa dentro dessa tela.
            onPressed: () => context.push('/restaurants/search-google'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              child: Column(
                children: [
                  AppSearchField(
                    controller: _queryController,
                    label: 'Buscar por nome',
                    onSubmit: (value) => ref
                        .read(restaurantsControllerProvider.notifier)
                        .search(value ?? ''),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSearchField(
                    controller: _cityController,
                    label: 'Filtrar por cidade',
                    onSubmit: (value) => ref
                        .read(restaurantsControllerProvider.notifier)
                        .applyFilters(city: value),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AppAnimatedSwitcher(
              child: switch (status) {
                RestaurantsInitial() ||
                RestaurantsLoading() ||
                RestaurantsSearching() ||
                RestaurantsFiltering() => const LoadingScreen(
                  key: ValueKey('loading'),
                ),
                RestaurantsError(:final message) => ErrorState(
                  key: const ValueKey('error'),
                  message: message,
                  onRetry: () => ref
                      .read(restaurantsControllerProvider.notifier)
                      .loadInitial(),
                ),
                RestaurantsEmpty() => const EmptyState(
                  key: ValueKey('empty'),
                  message: 'Nenhum restaurante encontrado.',
                ),
                RestaurantsLoaded(:final result) => ListView.builder(
                  key: const ValueKey('loaded'),
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final restaurant = result.items[index];
                    return AppStaggeredListItem(
                      index: index,
                      child: ListTile(
                        title: Text(restaurant.name),
                        subtitle: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/borah_location.png',
                              width: 14,
                              height: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [
                                  restaurant.category,
                                  if (restaurant.city != null) restaurant.city,
                                ].join(' · '),
                              ),
                            ),
                          ],
                        ),
                        trailing: restaurant.averageRating != null
                            ? ScoreBubble(rating: restaurant.averageRating)
                            : null,
                        onTap: () =>
                            context.push('/restaurants/${restaurant.id}'),
                      ),
                    );
                  },
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
