import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/inputs/app_search_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/google_place_search_controller.dart';
import '../../application/google_place_selection_controller.dart';
import '../../domain/google_place_result.dart';
import '../states/google_place_search_status.dart';
import '../states/google_place_selection_status.dart';

/// Busca de restaurantes reais via Google Places API (New) - F12. Entrada
/// principal do fluxo "Adicionar restaurante" (`RestaurantsSearchPage`);
/// `/restaurants/new` (cadastro 100% manual) continua existindo como
/// alternativa, oferecida aqui como link de saída, nunca removida.
class SearchGoogleRestaurantPage extends ConsumerStatefulWidget {
  const SearchGoogleRestaurantPage({super.key});

  @override
  ConsumerState<SearchGoogleRestaurantPage> createState() =>
      _SearchGoogleRestaurantPageState();
}

class _SearchGoogleRestaurantPageState
    extends ConsumerState<SearchGoogleRestaurantPage> {
  static const _debounceDuration = Duration(milliseconds: 500);

  final _queryController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  /// F12 §8 - nenhuma tecla dispara a busca diretamente; só depois de
  /// [_debounceDuration] sem uma tecla nova. Reinicia o timer a cada
  /// chamada (cancela o anterior), então só a última tecla de uma
  /// sequência rápida efetivamente aciona `GooglePlaceSearchController.
  /// search`.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      ref.read(googlePlaceSearchControllerProvider.notifier).search(value);
    });
  }

  void _selectPlace(GooglePlaceResult place) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref
        .read(googlePlaceSelectionControllerProvider.notifier)
        .selectPlace(place, createdBy: userId);
  }

  @override
  Widget build(BuildContext context) {
    final searchStatus = ref.watch(googlePlaceSearchControllerProvider);
    final selectionStatus = ref.watch(googlePlaceSelectionControllerProvider);
    final isResolving = selectionStatus is GooglePlaceSelectionResolving;

    ref.listen<GooglePlaceSelectionStatus>(
      googlePlaceSelectionControllerProvider,
      (previous, next) {
        if (next is GooglePlaceSelectionResolved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.wasCreated
                    ? 'Restaurante cadastrado.'
                    : 'Este restaurante já existe no BORAH.',
              ),
            ),
          );
          context.pushReplacement('/restaurants/${next.restaurant.id}');
        } else if (next is GooglePlaceSelectionError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.message)));
        }
      },
    );

    return Scaffold(
      appBar: const AppTopBar(title: 'Pesquisar restaurante'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppSearchField(
              controller: _queryController,
              label: 'Nome do restaurante ou cidade',
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: AbsorbPointer(
              absorbing: isResolving,
              child: AppAnimatedSwitcher(
                child: switch (searchStatus) {
                  GooglePlaceSearchInitial() => EmptyState(
                    key: const ValueKey('initial'),
                    message: 'Busque pelo nome de um restaurante real.',
                    action: AppOutlinedButton(
                      label: 'Cadastrar manualmente',
                      onPressed: () => context.push('/restaurants/new'),
                    ),
                  ),
                  GooglePlaceSearchLoading() => const _SearchLoadingState(
                    key: ValueKey('loading'),
                  ),
                  GooglePlaceSearchError(:final message) => ErrorState(
                    key: const ValueKey('error'),
                    message: message,
                    onRetry: () => ref
                        .read(googlePlaceSearchControllerProvider.notifier)
                        .search(_queryController.text),
                  ),
                  GooglePlaceSearchEmpty() => EmptyState(
                    key: const ValueKey('empty'),
                    message: 'Nenhum restaurante encontrado.',
                    action: AppOutlinedButton(
                      label: 'Cadastrar manualmente',
                      onPressed: () => context.push('/restaurants/new'),
                    ),
                  ),
                  GooglePlaceSearchLoaded(:final results) => ListView.builder(
                    key: const ValueKey('loaded'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
                      return AppStaggeredListItem(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            onTap: () => _selectPlace(place),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        place.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      if (place.address != null) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          place.address!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isResolving)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de carregamento com mensagem (F12 §14 - "Buscando
/// restaurantes...") - `LoadingScreen` do design system não expõe texto
/// (decisão própria dela, ver seu doc comment), então esta tela compõe
/// `LoadingIndicator` + `Text` diretamente, sem alterar o componente
/// compartilhado.
class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingIndicator(size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Buscando restaurantes...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
