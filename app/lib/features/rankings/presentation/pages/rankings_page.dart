import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/cards/ranking_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../groups/data/group_repository_impl.dart';
import '../../../groups/domain/group.dart';
import '../../application/rankings_controller.dart';
import '../../domain/ranked_restaurant.dart';
import '../../domain/ranking_scope.dart';
import '../states/rankings_status.dart';

/// Tela de Ranking de restaurantes (DV-05, ampliada pelo Item F - ranking
/// multi-escopo). "Global" preserva o comportamento original (todos os
/// restaurantes, por nota média pública); "Pessoal" mostra só os
/// restaurantes que o próprio usuário avaliou, pela nota que ele deu;
/// "Grupo" mostra os restaurantes dos rolês de um grupo escolhido, pela
/// média das avaliações coletivas. Os filtros de Cidade/Estado/País/
/// Categoria (antes sempre visíveis como 2 campos) viraram um bottom
/// sheet atrás do ícone de filtro do `AppTopBar` - 4 campos lado a lado
/// não cabiam de forma legível junto do seletor de escopo.
class RankingsPage extends ConsumerStatefulWidget {
  const RankingsPage({super.key});

  @override
  ConsumerState<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends ConsumerState<RankingsPage> {
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _categoryController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  RankingScope _scope = RankingScope.global;
  Group? _selectedGroup;
  List<Group>? _myGroups;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingsControllerProvider.notifier).load();
    });
    _loadMyGroups();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _categoryController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadMyGroups() async {
    try {
      final groups = await ref.read(groupRepositoryProvider).listMine();
      if (!mounted) return;
      setState(() => _myGroups = groups);
    } catch (_) {
      // Falha silenciosa: só degrada o seletor de grupo (mostra "Nenhum
      // grupo encontrado" em vez da lista) - não impede Global/Pessoal.
      if (!mounted) return;
      setState(() => _myGroups = const []);
    }
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _isLoadingMore = true;
    ref.read(rankingsControllerProvider.notifier).loadNextPage().whenComplete(
      () {
        if (mounted) _isLoadingMore = false;
      },
    );
  }

  String? _emptyText(String controller) =>
      controller.trim().isEmpty ? null : controller.trim();

  void _load() {
    final userId = ref.read(currentUserIdProvider);
    ref
        .read(rankingsControllerProvider.notifier)
        .load(
          scope: _scope,
          groupId: _scope == RankingScope.group ? _selectedGroup?.id : null,
          userId: _scope == RankingScope.personal ? userId : null,
          city: _emptyText(_cityController.text),
          state: _emptyText(_stateController.text),
          country: _emptyText(_countryController.text),
          category: _emptyText(_categoryController.text),
        );
  }

  void _onScopeChanged(RankingScope scope) {
    setState(() => _scope = scope);
    if (scope != RankingScope.group || _selectedGroup != null) _load();
  }

  Future<void> _pickGroup() async {
    final groups = _myGroups ?? const [];
    if (groups.isEmpty) return;
    final selected = await showModalBottomSheet<Group>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final group in groups)
                    ListTile(
                      title: Text(group.name),
                      onTap: () => Navigator.of(sheetContext).pop(group),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedGroup = selected);
    _load();
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtros', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(controller: _cityController, label: 'Cidade (opcional)'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _stateController,
                label: 'Estado (opcional)',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _countryController,
                label: 'País (opcional)',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _categoryController,
                label: 'Categoria (opcional)',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Aplicar',
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _load();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyMessage() => switch (_scope) {
    RankingScope.global => 'Nenhum restaurante avaliado ainda.',
    RankingScope.personal => 'Você ainda não avaliou nenhum restaurante.',
    RankingScope.group =>
      'Este grupo ainda não avaliou nenhum restaurante em seus rolês.',
  };

  String _trailingLabel(RankedRestaurant item) {
    final rating = item.rating.toStringAsFixed(1);
    return switch (_scope) {
      RankingScope.global => '$rating (${item.reviewsCount ?? 0})',
      RankingScope.personal => 'Sua nota: $rating',
      RankingScope.group =>
        '$rating (${item.reviewsCount ?? 0} '
            'avaliaç${(item.reviewsCount ?? 0) == 1 ? 'ão' : 'ões'} do grupo)',
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(rankingsControllerProvider);
    final needsGroupSelection =
        _scope == RankingScope.group && _selectedGroup == null;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Ranking',
        actions: [
          AppIconButton(
            icon: Icons.filter_list,
            tooltip: 'Filtros',
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                SegmentedButton<RankingScope>(
                  segments: const [
                    ButtonSegment(
                      value: RankingScope.global,
                      label: Text('Global'),
                    ),
                    ButtonSegment(
                      value: RankingScope.personal,
                      label: Text('Pessoal'),
                    ),
                    ButtonSegment(
                      value: RankingScope.group,
                      label: Text('Grupo'),
                    ),
                  ],
                  selected: {_scope},
                  onSelectionChanged: (selection) =>
                      _onScopeChanged(selection.first),
                ),
                if (_scope == RankingScope.group) ...[
                  const SizedBox(height: AppSpacing.md),
                  if (_myGroups == null)
                    const Center(child: LoadingIndicator(size: 24))
                  else if (_myGroups!.isEmpty)
                    const Text('Você precisa participar de um grupo.')
                  else
                    AppOutlinedButton(
                      label: _selectedGroup?.name ?? 'Selecionar grupo',
                      onPressed: _pickGroup,
                    ),
                ],
              ],
            ),
          ),
          Expanded(
            child: needsGroupSelection
                ? EmptyState(
                    message: (_myGroups ?? const []).isEmpty
                        ? 'Você precisa participar de um grupo para ver '
                              'este ranking.'
                        : 'Escolha um grupo para ver seu ranking de '
                              'restaurantes.',
                  )
                : AppAnimatedSwitcher(
                    child: switch (status) {
                      RankingsInitial() || RankingsLoading() =>
                        const LoadingScreen(key: ValueKey('loading')),
                      RankingsError(:final message) => ErrorState(
                        key: const ValueKey('error'),
                        message: message,
                        onRetry: _load,
                      ),
                      RankingsEmpty() => EmptyState(
                        key: const ValueKey('empty'),
                        message: _emptyMessage(),
                      ),
                      RankingsLoaded(:final result) => ListView.builder(
                        key: const ValueKey('loaded'),
                        controller: _scrollController,
                        itemCount: result.items.length,
                        itemBuilder: (context, index) {
                          final item = result.items[index];
                          final position = index + 1;
                          return AppStaggeredListItem(
                            index: index,
                            child: RankingCard(
                              position: position,
                              name: item.name,
                              subtitle: [
                                item.category,
                                if (item.city != null) item.city,
                              ].join(' · '),
                              trailingLabel: _trailingLabel(item),
                              onTap: () => context.push(
                                '/restaurants/${item.restaurantId}',
                              ),
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
