import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      ref.read(notificationsControllerProvider.notifier).loadForUser(userId);
    });
  }

  void _markAllAsRead() {
    ref.read(notificationsControllerProvider.notifier).markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/notifications/preferences'),
          ),
        ],
      ),
      body: switch (status) {
        NotificationsInitial() || NotificationsLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        NotificationsError(:final message) => Center(child: Text(message)),
        NotificationsEmpty() => const Center(
          child: Text('Nenhuma notificação ainda.'),
        ),
        NotificationsLoaded(:final result) => ListView.builder(
          itemCount: result.items.length,
          itemBuilder: (context, index) {
            final notification = result.items[index];
            return ListTile(
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
            );
          },
        ),
      },
    );
  }
}
