import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../users/presentation/widgets/profile_avatar.dart';
import '../../application/event_detail_controller.dart';
import '../../domain/event_attendance.dart';
import '../../domain/event_details.dart';
import '../states/event_detail_status.dart';

/// Tela de Detalhe do Rolê (ROLÊ-03) - restaurante/data + "X de Y
/// confirmaram" + lista de participantes. Na própria linha (comparação
/// com `currentUserIdProvider`, mesmo padrão de `comments_page.dart`),
/// se ainda pendente, mostra os botões de confirmar/recusar; senão, um
/// `AppBadge` com o status - mesmo padrão de exibição condicional de
/// `GroupDetailPage`/`comments_page.dart`. Sem editar, cancelar,
/// fotos, avaliação ou alternar resposta já dada - fora do escopo desta
/// sprint (decisão de produto aprovada: resposta única).
class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventDetailControllerProvider.notifier).load(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(eventDetailControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    ref.listen<EventDetailStatus>(eventDetailControllerProvider, (
      previous,
      next,
    ) {
      // Só mostra snackbar quando já havia um rolê carregado (falha de
      // confirmar/recusar) - a falha do `load()` inicial já vira tela de
      // erro no switch abaixo, sem precisar de feedback duplicado.
      if (next is EventDetailError && next.details != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Rolê'),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          EventDetailInitial() || EventDetailLoading() => const LoadingScreen(
            key: ValueKey('loading'),
          ),
          EventDetailError(:final message, details: null) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref
                .read(eventDetailControllerProvider.notifier)
                .load(widget.eventId),
          ),
          EventDetailLoaded(:final details) => _EventDetailContent(
            key: const ValueKey('loaded'),
            details: details,
            currentUserId: currentUserId,
          ),
          // Mesma `key` de `EventDetailLoaded` de propósito: uma falha em
          // confirmar/recusar não deve re-animar a tela inteira (o
          // `AppAnimatedSwitcher` trataria uma key diferente como um
          // widget novo) - só a linha revertida muda, o resto permanece
          // estável, com o erro chegando via snackbar (ver `ref.listen`).
          EventDetailError(:final details) => _EventDetailContent(
            key: const ValueKey('loaded'),
            details: details!,
            currentUserId: currentUserId,
          ),
        },
      ),
    );
  }
}

class _EventDetailContent extends ConsumerWidget {
  const _EventDetailContent({
    super.key,
    required this.details,
    required this.currentUserId,
  });

  final EventDetails details;
  final String? currentUserId;

  void _confirm(WidgetRef ref, String attendanceId) {
    ref.read(eventDetailControllerProvider.notifier).confirm(attendanceId);
  }

  void _decline(WidgetRef ref, String attendanceId) {
    ref.read(eventDetailControllerProvider.notifier).decline(attendanceId);
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year} às $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final event = details.event;
    final attendances = details.attendances;
    final subtitle = [
      event.restaurantCategory,
      event.restaurantCity,
    ].where((value) => value != null && value.isNotEmpty).join(' · ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.restaurantName ?? '',
            style: theme.textTheme.headlineSmall,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            _formatDateTime(event.scheduledAt),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${details.confirmedCount} de ${attendances.length} confirmaram',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...attendances.indexed.map(
            (entry) => AppStaggeredListItem(
              index: entry.$1,
              child: _AttendanceTile(
                attendance: entry.$2,
                isOwn: entry.$2.userId == currentUserId,
                onConfirm: () => _confirm(ref, entry.$2.id),
                onDecline: () => _decline(ref, entry.$2.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.attendance,
    required this.isOwn,
    required this.onConfirm,
    required this.onDecline,
  });

  final EventAttendance attendance;
  final bool isOwn;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: ProfileAvatar(avatarPath: attendance.avatarUrl, radius: 20),
      title: Text(attendance.fullName ?? ''),
      trailing: isOwn && attendance.isPending
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconButton(
                  icon: Icons.check_circle_outline,
                  tooltip: 'Confirmar presença',
                  color: scheme.primary,
                  onPressed: onConfirm,
                ),
                AppIconButton(
                  icon: Icons.cancel_outlined,
                  tooltip: 'Recusar',
                  color: scheme.error,
                  onPressed: onDecline,
                ),
              ],
            )
          : AppBadge(
              label: attendance.statusLabel,
              earned: attendance.isConfirmed,
            ),
    );
  }
}
