import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_tabs.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/feed_controller.dart';
import '../states/feed_status.dart';
import '../widgets/social_feed_card.dart';

/// Tela de Feed (FASE SOCIAL 4) - o coração social do BORAH. Duas abas:
/// "Para Você" (descoberta determinística - seguidos, pessoas de grupos em
/// comum, entradas em grupos públicos) e "Seguindo" (só quem o usuário
/// segue). Cada aba tem seu próprio controller/paginação, preservados ao
/// trocar de aba (`AppTabs`/`TabBarView` mantém as duas construídas).
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Feed',
        actions: [
          AppIconButton(
            icon: Icons.search,
            tooltip: 'Pesquisar',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: AppTabs(
        tabs: [
          AppTabItem(
            label: 'Para Você',
            child: _FeedTabView(
              emptyMessage:
                  'Comece a seguir pessoas e grupos para personalizar seu Feed.',
              emptyAction: AppOutlinedButton(
                label: 'Explorar pessoas e grupos',
                onPressed: () => context.push('/search'),
              ),
              watchStatus: (ref) => ref.watch(feedForYouControllerProvider),
              notifierOf: (ref) =>
                  ref.read(feedForYouControllerProvider.notifier),
            ),
          ),
          AppTabItem(
            label: 'Seguindo',
            child: _FeedTabView(
              emptyMessage: 'Nenhuma atividade de quem você segue ainda.',
              watchStatus: (ref) => ref.watch(feedFollowingControllerProvider),
              notifierOf: (ref) =>
                  ref.read(feedFollowingControllerProvider.notifier),
            ),
          ),
        ],
      ),
    );
  }
}

/// Conteúdo de uma aba do Feed - idêntico entre "Para Você"/"Seguindo",
/// só a fonte ([watchStatus]/[notifierOf]) muda. Recebe funções (não o
/// provider em si) para evitar problemas de variância genérica entre
/// `NotifierProvider<FeedForYouController, FeedStatus>` e
/// `NotifierProvider<FeedFollowingController, FeedStatus>`.
class _FeedTabView extends ConsumerStatefulWidget {
  const _FeedTabView({
    required this.emptyMessage,
    required this.watchStatus,
    required this.notifierOf,
    this.emptyAction,
  });

  final String emptyMessage;
  final Widget? emptyAction;
  final FeedStatus Function(WidgetRef ref) watchStatus;
  final FeedControllerBase Function(WidgetRef ref) notifierOf;

  @override
  ConsumerState<_FeedTabView> createState() => _FeedTabViewState();
}

class _FeedTabViewState extends ConsumerState<_FeedTabView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _load() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    widget.notifierOf(ref).loadForUser(userId);
  }

  Future<void> _refresh() {
    return widget.notifierOf(ref).refresh();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _isLoadingMore = true;
    widget.notifierOf(ref).loadNextPage().whenComplete(() {
      if (mounted) _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final status = widget.watchStatus(ref);
    final currentUserId = ref.watch(currentUserIdProvider) ?? '';

    return AppAnimatedSwitcher(
      child: switch (status) {
        FeedInitial() ||
        FeedLoading() => const LoadingScreen(key: ValueKey('loading')),
        FeedError(:final message) => ErrorState(
          key: const ValueKey('error'),
          message: message,
          onRetry: _load,
        ),
        FeedEmpty() => EmptyState(
          key: const ValueKey('empty'),
          message: widget.emptyMessage,
          action: widget.emptyAction,
        ),
        FeedRefreshing(:final result) ||
        FeedLoaded(:final result) => RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: _refresh,
          child: ListView.builder(
            controller: _scrollController,
            // Sem isto, um `ScrollController` explícito desativa o scroll
            // "sempre disponível" que `RefreshIndicator` precisa para
            // funcionar em listas pequenas (que não preenchem a
            // viewport) - mesma regressão real já documentada no Feed
            // anterior.
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final item = result.items[index];
              return AppStaggeredListItem(
                index: index,
                child: SocialFeedCard(
                  key: ValueKey(item.feedKey),
                  item: item,
                  currentUserId: currentUserId,
                ),
              );
            },
          ),
        ),
      },
    );
  }
}
