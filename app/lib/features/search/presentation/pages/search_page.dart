import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/feedback/score_bubble.dart';
import '../../../../design_system/components/inputs/app_search_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../groups/data/group_repository_impl.dart';
import '../../../groups/domain/group.dart';
import '../../../groups/presentation/widgets/group_result_tile.dart';
import '../../../restaurants/domain/restaurant.dart';
import '../../../social/data/follower_repository_impl.dart';
import '../../../social/presentation/widgets/person_list_tile.dart';
import '../../../users/domain/user_profile.dart';
import '../../application/discovery_controller.dart';
import '../../application/featured_groups_controller.dart';
import '../../application/search_controller.dart';
import '../states/discovery_status.dart';
import '../states/featured_groups_status.dart';
import '../states/search_status.dart';

/// Tela de Pesquisa/Explorar social (FASE SOCIAL 1-3) - Pessoas, Grupos
/// e Restaurantes numa única tela com seções, mesmo padrão de
/// busca-no-submit já usado em `restaurants_search_page.dart`. Antes de
/// qualquer busca, mostra "Você pode conhecer" + "Grupos em destaque"
/// (FASE SOCIAL 2/3) em vez de uma tela vazia - a decisão de UX
/// aprovada foi manter Explorar como o estado inicial desta tela, não
/// como abas novas.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _queryController = TextEditingController();

  // FASE SOCIAL 2 - status de Seguir/Seguindo por pessoa, buscado em
  // lote (`listFollowingAmong`) conforme novos ids aparecem em qualquer
  // uma das 2 fontes desta tela (busca de pessoas, Você pode conhecer) -
  // nunca 1 consulta por linha.
  Set<String> _followingIds = {};
  final Set<String> _followingStatusKnownIds = {};

  // FASE SOCIAL 3 - grupos dos quais o usuário já é membro, para marcar
  // "Você participa" em vez de "Entrar" (decisão de produto: nunca
  // esconder um grupo relevante da busca/destaque só porque o usuário
  // já participa dele). Buscado 1 vez - diferente de seguidores, a
  // lista de grupos de uma pessoa é naturalmente pequena, sem motivo
  // para o mesmo mecanismo incremental de `_followingIds`.
  Set<String> _myGroupIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.read(discoveryControllerProvider.notifier).load(userId);
        _loadMyGroupIds(userId);
      }
      ref.read(featuredGroupsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search(String? value) {
    ref.read(searchControllerProvider.notifier).search(value ?? '');
  }

  Future<void> _loadMyGroupIds(String userId) async {
    try {
      final ids = await ref
          .read(groupRepositoryProvider)
          .listMyGroupIds(userId);
      if (!mounted) return;
      setState(() => _myGroupIds = ids);
    } catch (_) {
      // Falha silenciosa: sem essa marcação, um grupo do qual o usuário
      // já participa só mostraria "Entrar" em vez de "Você participa" -
      // degradação aceitável, não impede o uso da busca.
    }
  }

  void _openGroup(Group group) {
    final destination = _myGroupIds.contains(group.id)
        ? '/groups/${group.id}'
        : '/groups/${group.id}/preview';
    context.push(destination);
  }

  Future<void> _syncFollowingStatus(List<UserProfile> people) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null || people.isEmpty) return;

    final newIds = people
        .map((p) => p.id)
        .where((id) => !_followingStatusKnownIds.contains(id))
        .toList();
    if (newIds.isEmpty) return;

    try {
      final result = await ref
          .read(followerRepositoryProvider)
          .listFollowingAmong(currentUserId, newIds);
      if (!mounted) return;
      setState(() {
        _followingIds = {..._followingIds, ...result};
        _followingStatusKnownIds.addAll(newIds);
      });
    } catch (_) {
      // Falha silenciosa: os botões ficam como "Seguir" até a próxima
      // tentativa - não é grave o suficiente para bloquear a tela.
    }
  }

  Future<void> _loadMoreSuggestions() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final success = await ref
        .read(discoveryControllerProvider.notifier)
        .loadMore(userId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar mais sugestões.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(searchControllerProvider);
    final discoveryStatus = ref.watch(discoveryControllerProvider);
    final featuredGroupsStatus = ref.watch(featuredGroupsControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    ref.listen<SearchStatus>(searchControllerProvider, (previous, next) {
      if (next is SearchLoaded) _syncFollowingStatus(next.people.items);
    });
    ref.listen<DiscoveryStatus>(discoveryControllerProvider, (previous, next) {
      if (next is DiscoveryLoaded) _syncFollowingStatus(next.people);
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Pesquisar'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppSearchField(
              controller: _queryController,
              label: 'Pesquisar no BORAH',
              onSubmit: _search,
            ),
          ),
          Expanded(
            child: AppAnimatedSwitcher(
              child: switch (status) {
                SearchInitial() => _ExploreView(
                  key: const ValueKey('explore'),
                  discoveryStatus: discoveryStatus,
                  featuredGroupsStatus: featuredGroupsStatus,
                  currentUserId: currentUserId,
                  followingIds: _followingIds,
                  myGroupIds: _myGroupIds,
                  onLoadMoreSuggestions: _loadMoreSuggestions,
                  onLoadMoreGroups: () => ref
                      .read(featuredGroupsControllerProvider.notifier)
                      .loadMore(),
                  onOpenGroup: _openGroup,
                ),
                SearchLoading() => const LoadingScreen(
                  key: ValueKey('loading'),
                ),
                SearchError(:final message) => ErrorState(
                  key: const ValueKey('error'),
                  message: message,
                  onRetry: () => _search(_queryController.text),
                ),
                SearchLoaded(
                  :final people,
                  :final groups,
                  :final restaurants,
                ) =>
                  _SearchResults(
                    key: const ValueKey('loaded'),
                    people: people.items,
                    groups: groups.items,
                    restaurants: restaurants.items,
                    currentUserId: currentUserId,
                    followingIds: _followingIds,
                    myGroupIds: _myGroupIds,
                    onOpenGroup: _openGroup,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado inicial da tela (antes de qualquer busca) - "Você pode
/// conhecer" (FASE SOCIAL 2) + "Grupos em destaque" (FASE SOCIAL 3).
class _ExploreView extends StatelessWidget {
  const _ExploreView({
    super.key,
    required this.discoveryStatus,
    required this.featuredGroupsStatus,
    required this.currentUserId,
    required this.followingIds,
    required this.myGroupIds,
    required this.onLoadMoreSuggestions,
    required this.onLoadMoreGroups,
    required this.onOpenGroup,
  });

  final DiscoveryStatus discoveryStatus;
  final FeaturedGroupsStatus featuredGroupsStatus;
  final String? currentUserId;
  final Set<String> followingIds;
  final Set<String> myGroupIds;
  final Future<void> Function() onLoadMoreSuggestions;
  final Future<void> Function() onLoadMoreGroups;
  final void Function(Group) onOpenGroup;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Busque por pessoas, grupos ou restaurantes.'),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(title: 'Você pode conhecer'),
        ),
        switch (discoveryStatus) {
          DiscoveryInitial() || DiscoveryLoading() => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              key: ValueKey('discovery-loading'),
              child: LoadingIndicator(size: 28),
            ),
          ),
          DiscoveryError(:final message) => Padding(
            key: const ValueKey('discovery-error'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(message),
          ),
          DiscoveryEmpty() => const Padding(
            key: ValueKey('discovery-empty'),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text('Nenhuma sugestão disponível no momento.'),
          ),
          DiscoveryLoaded(:final people, :final hasMore) => Column(
            key: const ValueKey('discovery-loaded'),
            children: [
              for (final person in people)
                PersonListTile(
                  person: person,
                  currentUserId: currentUserId,
                  initialIsFollowing: followingIds.contains(person.id),
                  onTap: () => context.push('/users/${person.id}'),
                ),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: AppTextButton(
                    label: 'Ver mais',
                    onPressed: onLoadMoreSuggestions,
                  ),
                ),
            ],
          ),
        },
        const SizedBox(height: AppSpacing.lg),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(title: 'Grupos em destaque'),
        ),
        switch (featuredGroupsStatus) {
          FeaturedGroupsInitial() || FeaturedGroupsLoading() => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              key: ValueKey('featured-groups-loading'),
              child: LoadingIndicator(size: 28),
            ),
          ),
          FeaturedGroupsError(:final message) => Padding(
            key: const ValueKey('featured-groups-error'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(message),
          ),
          FeaturedGroupsEmpty() => const Padding(
            key: ValueKey('featured-groups-empty'),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text('Nenhum grupo público em destaque no momento.'),
          ),
          FeaturedGroupsLoaded(:final groups, :final hasMore) => Column(
            key: const ValueKey('featured-groups-loaded'),
            children: [
              for (final group in groups)
                GroupResultTile(
                  group: group,
                  isMember: myGroupIds.contains(group.id),
                  onTap: () => onOpenGroup(group),
                ),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: AppTextButton(
                    label: 'Ver mais',
                    onPressed: onLoadMoreGroups,
                  ),
                ),
            ],
          ),
        },
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    super.key,
    required this.people,
    required this.groups,
    required this.restaurants,
    required this.currentUserId,
    required this.followingIds,
    required this.myGroupIds,
    required this.onOpenGroup,
  });

  final List<UserProfile> people;
  final List<Group> groups;
  final List<Restaurant> restaurants;
  final String? currentUserId;
  final Set<String> followingIds;
  final Set<String> myGroupIds;
  final void Function(Group) onOpenGroup;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty && groups.isEmpty && restaurants.isEmpty) {
      return const EmptyState(message: 'Nenhum resultado encontrado.');
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(title: 'Pessoas'),
        ),
        if (people.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text('Nenhuma pessoa encontrada.'),
          )
        else
          for (final person in people)
            PersonListTile(
              person: person,
              currentUserId: currentUserId,
              initialIsFollowing: followingIds.contains(person.id),
              onTap: () => context.push('/users/${person.id}'),
            ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: SectionHeader(title: 'Grupos'),
        ),
        if (groups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text('Nenhum grupo encontrado.'),
          )
        else
          for (final group in groups)
            GroupResultTile(
              group: group,
              isMember: myGroupIds.contains(group.id),
              onTap: () => onOpenGroup(group),
            ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: SectionHeader(title: 'Restaurantes'),
        ),
        if (restaurants.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text('Nenhum restaurante encontrado.'),
          )
        else
          for (final restaurant in restaurants)
            ListTile(
              title: Text(restaurant.name),
              subtitle: Text(
                [
                  restaurant.category,
                  if (restaurant.city != null) restaurant.city,
                ].join(' · '),
              ),
              trailing: restaurant.averageRating != null
                  ? ScoreBubble(rating: restaurant.averageRating)
                  : null,
              onTap: () => context.push('/restaurants/${restaurant.id}'),
            ),
      ],
    );
  }
}
