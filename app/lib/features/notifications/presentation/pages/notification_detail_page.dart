import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/notifications_controller.dart';
import '../../domain/app_notification.dart';

/// Tela de Detalhes da Notificação (DV-09 §6) - marca como lida ao abrir
/// e navega usando os identificadores do `payload` (decisão 6 do DV-09),
/// reaproveitando as rotas já existentes (`/users/:id`, `/reviews/:id`).
class NotificationDetailPage extends ConsumerStatefulWidget {
  const NotificationDetailPage({super.key, required this.notification});

  final AppNotification notification;

  @override
  ConsumerState<NotificationDetailPage> createState() =>
      _NotificationDetailPageState();
}

class _NotificationDetailPageState
    extends ConsumerState<NotificationDetailPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.notification.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(notificationsControllerProvider.notifier)
            .markAsRead(widget.notification.id);
      });
    }
  }

  void _navigateToTarget() {
    final payload = widget.notification.payload;
    if (payload == null) return;

    switch (widget.notification.type) {
      case 'new_follower':
        final followerId = payload['follower_id'] as String?;
        if (followerId != null) context.push('/users/$followerId');
      case 'new_comment':
      case 'new_like':
        final reviewId = payload['review_id'] as String?;
        if (reviewId != null) context.push('/reviews/$reviewId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificação')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(notification.message),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _navigateToTarget,
              child: const Text('Ver'),
            ),
          ],
        ),
      ),
    );
  }
}
