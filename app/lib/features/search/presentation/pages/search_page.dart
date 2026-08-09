import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/feedback/score_bubble.dart';
import '../../../../design_system/components/inputs/app_search_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../restaurants/domain/restaurant.dart';
import '../../../users/domain/user_profile.dart';
import '../../../users/presentation/widgets/profile_avatar.dart';
import '../../application/search_controller.dart';
import '../states/search_status.dart';

/// Tela de Pesquisa social (FASE SOCIAL 1) - Pessoas, Grupos e
/// Restaurantes numa única tela com seções, mesmo padrão de busca-no-
/// submit já usado em `restaurants_search_page.dart`.
///
/// A seção Grupos é fixa/explicativa, não uma busca real: grupos são
/// 100% privados hoje (RLS bloqueia SELECT para não-membros) - buscar
/// grupos públicos exige `groups.visibility` + policy nova, fora do
/// escopo desta fase (ver PLANO UX/TÉCNICO — Fluxo da Pesquisa).
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search(String? value) {
    ref.read(searchControllerProvider.notifier).search(value ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(searchControllerProvider);

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
                SearchInitial() => const EmptyState(
                  key: ValueKey('initial'),
                  message: 'Busque por pessoas ou restaurantes.',
                ),
                SearchLoading() => const LoadingScreen(
                  key: ValueKey('loading'),
                ),
                SearchError(:final message) => ErrorState(
                  key: const ValueKey('error'),
                  message: message,
                  onRetry: () => _search(_queryController.text),
                ),
                SearchLoaded(:final people, :final restaurants) =>
                  _SearchResults(
                    key: const ValueKey('loaded'),
                    people: people.items,
                    restaurants: restaurants.items,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    super.key,
    required this.people,
    required this.restaurants,
  });

  final List<UserProfile> people;
  final List<Restaurant> restaurants;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty && restaurants.isEmpty) {
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
            ListTile(
              leading: ProfileAvatar(avatarPath: person.avatarUrl, radius: 20),
              title: Text(
                person.fullName?.isNotEmpty == true
                    ? person.fullName!
                    : 'Sem nome',
              ),
              subtitle: person.bio != null && person.bio!.isNotEmpty
                  ? Text(
                      person.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
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
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          // FASE SOCIAL 1: busca de grupos públicos ainda não é possível
          // (ver doc-comment de SearchPage) - mensagem explicativa, não
          // um estado de carregamento/erro.
          child: Text('Busca de grupos públicos chega em breve.'),
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
