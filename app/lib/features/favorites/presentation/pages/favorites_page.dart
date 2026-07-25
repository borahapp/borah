import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/paged_result.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/feedback/score_bubble.dart';
import '../../../../design_system/components/inputs/app_search_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../restaurants/domain/restaurant.dart';
import '../../application/favorites_controller.dart';
import '../../domain/favorite_sort_by.dart';
import '../states/favorites_status.dart';

/// Tela de Lista de Favoritos (DV-06 §6): busca por nome, filtro por
/// cidade e ordenação (nome/avaliação/data) - tudo no mesmo
/// `FavoritesController.loadForUser`.
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final _queryController = TextEditingController();
  final _cityController = TextEditingController();
  FavoriteSortBy _sortBy = FavoriteSortBy.date;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      ref.read(favoritesControllerProvider.notifier).loadForUser(userId);
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref
        .read(favoritesControllerProvider.notifier)
        .loadForUser(
          userId,
          query: _queryController.text.trim(),
          city: _cityController.text.trim(),
          sortBy: _sortBy,
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(favoritesControllerProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Favoritos'),
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
                    onSubmit: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSearchField(
                    controller: _cityController,
                    label: 'Filtrar por cidade',
                    onSubmit: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButton<FavoriteSortBy>(
                    value: _sortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: FavoriteSortBy.date,
                        child: Text('Mais recentes'),
                      ),
                      DropdownMenuItem(
                        value: FavoriteSortBy.name,
                        child: Text('Nome'),
                      ),
                      DropdownMenuItem(
                        value: FavoriteSortBy.rating,
                        child: Text('Avaliação'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortBy = value);
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AppAnimatedSwitcher(
              child: switch (status) {
                FavoritesInitial() || FavoritesLoading() => const LoadingScreen(
                  key: ValueKey('loading'),
                ),
                FavoritesError(:final message) => Center(
                  key: const ValueKey('error'),
                  child: Text(message),
                ),
                FavoritesEmpty() => const EmptyState(
                  key: ValueKey('empty'),
                  message: 'Você ainda não tem favoritos.',
                ),
                FavoritesSyncing(:final result) ||
                FavoritesLoaded(:final result) => _FavoritesList(
                  key: const ValueKey('loaded'),
                  result: result,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({super.key, required this.result});

  final PagedResult<Restaurant> result;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
            onTap: () => context.push('/restaurants/${restaurant.id}'),
          ),
        );
      },
    );
  }
}
