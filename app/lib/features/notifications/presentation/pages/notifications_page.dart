import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/notifications_controller.dart';
import '../states/notifications_status.dart';

/// Central de Notificações (DV-09 §6). Tocar em uma notificação leva aos
/// Detalhes, que marca como lida e permite navegar via `payload`.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      ref.read(notificationsControllerProvider.notifier).loadForUser(userId);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _markAllAsRead() {
    ref.read(notificationsControllerProvider.notifier).markAllAsRead();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _isLoadingMore = true;
    ref
        .read(notificationsControllerProvider.notifier)
        .loadNextPage()
        .whenComplete(() {
          if (mounted) _isLoadingMore = false;
        });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Notificações',
        actions: [
          AppIconButton(
            icon: Icons.done_all,
            tooltip: 'Marcar todas como lidas',
            onPressed: _markAllAsRead,
          ),
          AppIconButton(
            icon: Icons.settings,
            tooltip: 'Preferências de notificação',
            onPressed: () => context.push('/notifications/preferences'),
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          NotificationsInitial() || NotificationsLoading() =>
            const LoadingScreen(key: ValueKey('loading')),
          NotificationsError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null) return;
              ref
                  .read(notificationsControllerProvider.notifier)
                  .loadForUser(userId);
            },
          ),
          NotificationsEmpty() => const EmptyState(
            key: ValueKey('empty'),
            message: 'Nenhuma notificação ainda.',
          ),
          NotificationsLoaded(:final result) => ListView.builder(
            key: const ValueKey('loaded'),
            controller: _scrollController,
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final notification = result.items[index];
              return AppStaggeredListItem(
                index: index,
                child: ListTile(
                  leading: notification.isRead
                      ? const SizedBox(width: 10, height: 10)
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notification.message),
                  onTap: () => context.push(
                    '/notifications/${notification.id}',
                    extra: notification,
                  ),
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
