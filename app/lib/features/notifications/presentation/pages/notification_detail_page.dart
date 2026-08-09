import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/notifications_controller.dart';
import '../../domain/app_notification.dart';

/// Tela de Detalhes da Notificação (DV-09 §6; tipos de Grupos/Rolês no
/// BLOCO 8) - marca como lida ao abrir e navega usando os
/// identificadores do `payload` (decisão 6 do DV-09), reaproveitando as
/// rotas já existentes (`/users/:id`, `/reviews/:id`, `/groups/:id`,
/// `/groups/:groupId/events/:eventId`, `/gamification`) - nenhuma rota
/// nova. `level_up`/`badge_earned` (DV-10) para `/gamification` foi um
/// achado de QA (BLOCO 9): o botão "Ver" não tinha destino para esses
/// 2 tipos até então.
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

  // Reescrito de `switch`/`case` para `if` na revisão do BLOCO 8 - mesma
  // troca já feita em `group_detail_page.dart` (BLOCO 2): cada ramo
  // aqui tem instruções próprias sem `break`/`return` explícito, o que
  // arrisca fall-through indevido entre cases num switch statement
  // comum (diferente dos `switch` *expression* usados nos controllers/
  // páginas deste projeto, que sempre retornam um valor por `=>`).
  void _navigateToTarget() {
    final payload = widget.notification.payload;
    if (payload == null) return;

    final type = widget.notification.type;

    if (type == 'new_follower') {
      final followerId = payload['follower_id'] as String?;
      if (followerId != null) context.push('/users/$followerId');
    }
    if (type == 'new_comment' || type == 'new_like') {
      final reviewId = payload['review_id'] as String?;
      if (reviewId != null) context.push('/reviews/$reviewId');
    }
    // BLOCO 8: mesmo padrão - reaproveita as rotas de Grupos/Rolês já
    // existentes, sem nenhuma rota nova para notificações.
    if (type == 'group_member_joined') {
      final groupId = payload['group_id'] as String?;
      if (groupId != null) context.push('/groups/$groupId');
    }
    // FASE C.4: mesmo destino de 'new_event'/'event_attendance_response'
    // - a tela de Detalhe do rolê já é onde o botão "Avaliar" aparece
    // (EventDetailPage, condicionado a `canReview`), nenhuma rota nova.
    if (type == 'new_event' ||
        type == 'event_attendance_response' ||
        type == 'event_review_open') {
      final groupId = payload['group_id'] as String?;
      final eventId = payload['event_id'] as String?;
      if (groupId != null && eventId != null) {
        context.push('/groups/$groupId/events/$eventId');
      }
    }
    // Achado de QA (BLOCO 9): 'level_up'/'badge_earned' (DV-10) não
    // tinham nenhum destino aqui - o botão "Ver" não fazia nada ao
    // tocar. Nenhum id específico no payload aponta para uma tela
    // própria (level_up só tem `level`; badge_earned tem `badge_id`,
    // mas não existe tela de detalhe de badge) - `/gamification` (perfil
    // de gamificação, já existente) é o destino natural dos dois.
    if (type == 'level_up' || type == 'badge_earned') {
      context.push('/gamification');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    return Scaffold(
      appBar: const AppTopBar(title: 'Notificação'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(notification.message),
            const SizedBox(height: AppSpacing.xl),
            AppOutlinedButton(label: 'Ver', onPressed: _navigateToTarget),
          ],
        ),
      ),
    );
  }
}
