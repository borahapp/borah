import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/collection_utils.dart';
import '../../../../design_system/components/badges/app_badge.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/dialogs/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../event_reviews/application/event_reviews_controller.dart';
import '../../../event_reviews/domain/event_review.dart';
import '../../../event_reviews/presentation/states/event_reviews_status.dart';
import '../../../users/presentation/widgets/profile_avatar.dart';
import '../../application/event_detail_controller.dart';
import '../../domain/event.dart';
import '../../domain/event_attendance.dart';
import '../../domain/event_details.dart';
import '../states/event_detail_status.dart';

/// Tela de Detalhe do Rolê (ROLÊ-03; cancelar/reagendar no BLOCO 3;
/// avaliação coletiva no BLOCO 4) - restaurante/data + "X de Y
/// confirmaram" + lista de participantes + seção de avaliação coletiva.
/// Na própria linha (comparação com `currentUserIdProvider`), se ainda
/// pendente, mostra os botões de confirmar/recusar; senão, um
/// `AppBadge` com o status. Cancelar/reagendar só aparecem para
/// admin/owner do grupo (`EventDetailStatus.canManage`) e só enquanto o
/// rolê ainda está `scheduled`. Avaliar só aparece para quem confirmou
/// presença, depois que o rolê já aconteceu (`Event.hasHappened`) e não
/// foi cancelado - a RLS (`can_review_event`) impõe a mesma regra; isto
/// só evita mostrar um botão que ela rejeitaria.
class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({
    super.key,
    required this.eventId,
    required this.groupId,
  });

  final String eventId;
  final String groupId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(eventDetailControllerProvider.notifier)
          .load(widget.eventId, widget.groupId);
      ref.read(eventReviewsControllerProvider.notifier).load(widget.eventId);
    });
  }

  Future<void> _cancelEvent() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancelar rolê',
      message: 'Ninguém poderá mais confirmar presença. Deseja continuar?',
      confirmLabel: 'Cancelar rolê',
      isDestructive: true,
    );
    if (!confirmed) return;
    ref.read(eventDetailControllerProvider.notifier).cancel(widget.eventId);
  }

  Future<void> _rescheduleEvent(DateTime currentScheduledAt) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentScheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentScheduledAt),
    );
    if (time == null) return;

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    ref
        .read(eventDetailControllerProvider.notifier)
        .reschedule(widget.eventId, scheduledAt);
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
      // confirmar/recusar/cancelar/reagendar) - a falha do `load()`
      // inicial já vira tela de erro no switch abaixo.
      if (next is EventDetailError && next.details != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final canManage = switch (status) {
      EventDetailLoaded(:final canManage) => canManage,
      EventDetailError(:final canManage) => canManage,
      _ => false,
    };
    final event = switch (status) {
      EventDetailLoaded(:final details) => details.event,
      EventDetailError(:final details) => details?.event,
      _ => null,
    };
    final canCancelOrReschedule = canManage && event?.status == 'scheduled';

    return Scaffold(
      appBar: AppTopBar(
        title: 'Rolê',
        actions: [
          if (canCancelOrReschedule) ...[
            AppIconButton(
              icon: Icons.schedule_outlined,
              tooltip: 'Reagendar',
              onPressed: () => _rescheduleEvent(event!.scheduledAt),
            ),
            AppIconButton(
              icon: Icons.event_busy_outlined,
              tooltip: 'Cancelar rolê',
              onPressed: _cancelEvent,
            ),
          ],
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          EventDetailInitial() ||
          EventDetailLoading() => const LoadingScreen(key: ValueKey('loading')),
          EventDetailError(:final message, details: null) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () => ref
                .read(eventDetailControllerProvider.notifier)
                .load(widget.eventId, widget.groupId),
          ),
          EventDetailLoaded(:final details) => _EventDetailContent(
            key: const ValueKey('loaded'),
            groupId: widget.groupId,
            details: details,
            currentUserId: currentUserId,
          ),
          // Mesma `key` de `EventDetailLoaded` de propósito: uma falha em
          // confirmar/recusar/cancelar/reagendar não deve re-animar a
          // tela inteira (o `AppAnimatedSwitcher` trataria uma key
          // diferente como um widget novo) - o erro chega via snackbar
          // (ver `ref.listen`).
          EventDetailError(:final details) => _EventDetailContent(
            key: const ValueKey('loaded'),
            groupId: widget.groupId,
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
    required this.groupId,
    required this.details,
    required this.currentUserId,
  });

  final String groupId;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  event.restaurantName ?? '',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              if (event.status != 'scheduled')
                AppBadge(label: event.statusLabel, earned: false),
            ],
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
                // Responder só faz sentido enquanto o rolê ainda pode
                // acontecer - um rolê cancelado não aceita mais
                // confirmação/recusa (BLOCO 3).
                isOwn:
                    entry.$2.userId == currentUserId &&
                    event.status == 'scheduled',
                onConfirm: () => _confirm(ref, entry.$2.id),
                onDecline: () => _decline(ref, entry.$2.id),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ReviewsSection(
            groupId: groupId,
            event: event,
            averageRating: event.averageRating,
            totalReviews: event.totalReviews,
            // Só quem confirmou presença, depois que o rolê já
            // aconteceu e não foi cancelado (BLOCO 4) - mesma regra de
            // `can_review_event()` no banco.
            canReview:
                event.status == 'scheduled' &&
                event.hasHappened &&
                (details.ownAttendance(currentUserId)?.isConfirmed ?? false),
            currentUserId: currentUserId,
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

/// Seção de Avaliação Coletiva (BLOCO 4) - controller próprio
/// (`eventReviewsControllerProvider`), independente de
/// `EventDetailController`, mesmo padrão de `FavoriteToggleController`
/// coexistir com o controller de detalhe do restaurante na mesma tela.
class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({
    required this.groupId,
    required this.event,
    required this.averageRating,
    required this.totalReviews,
    required this.canReview,
    required this.currentUserId,
  });

  final String groupId;

  /// Rolê completo (não só o `id`) - RC-03 FASE A1: a tela de avaliação
  /// coletiva passa a mostrar nome/data/foto do restaurante, já
  /// disponíveis aqui sem nenhuma consulta nova.
  final Event event;

  /// Direto de `Event.averageRating`/`totalReviews` - agregado já
  /// calculado no banco (trigger), sem recomputar aqui a partir de
  /// `reviews` (evitaria divergir do valor oficial em caso de paginação
  /// futura da lista).
  final double? averageRating;
  final int totalReviews;
  final bool canReview;
  final String? currentUserId;

  String get eventId => event.id;

  Future<void> _openReviewForm(
    BuildContext context,
    WidgetRef ref,
    EventReview? existing,
  ) async {
    await context.push(
      '/groups/$groupId/events/$eventId/review',
      extra: (event: event, existingReview: existing),
    );
    // submit_event_review_page.dart só fecha (`context.pop()`, sem
    // valor de retorno) - recarrega os dois controllers ao voltar: a
    // lista de avaliações (nova/editada) e o detalhe do rolê (a média
    // agregada em `Event.averageRating`/`totalReviews` mudou).
    ref.read(eventReviewsControllerProvider.notifier).load(eventId);
    ref.read(eventDetailControllerProvider.notifier).load(eventId, groupId);
  }

  EventReview? _findOwnReview(List<EventReview> reviews, String? userId) {
    if (userId == null) return null;
    return firstWhereOrNull(reviews, (review) => review.userId == userId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(eventReviewsControllerProvider);
    final theme = Theme.of(context);
    final reviews = status is EventReviewsLoaded
        ? status.reviews
        : const <EventReview>[];
    final ownReview = _findOwnReview(reviews, currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Avaliação coletiva'),
        const SizedBox(height: AppSpacing.sm),
        // "Nota final" (pedido do produto): média simples dos 5
        // critérios entre todos os participantes - "média" e "média
        // ponderada" colapsam no mesmo número aqui, decisão registrada
        // na migration (sem esquema de pesos por critério especificado).
        if (averageRating != null)
          Text(
            '${averageRating!.toStringAsFixed(1)} ⭐ · baseada em '
            '$totalReviews ${totalReviews == 1 ? "avaliação" : "avaliações"}',
            style: theme.textTheme.titleMedium,
          ),
        const SizedBox(height: AppSpacing.sm),
        // Mesmo padrão de seção embutida de `public_profile_page.dart`
        // ("Avaliações" do perfil): `AppAnimatedSwitcher` com um estado
        // por `ValueKey`, `LoadingIndicator` inline (não `LoadingScreen`,
        // que é para a tela cheia) - substitui o antigo `SizedBox.
        // shrink()` que escondia a seção inteira (título incluso)
        // enquanto `EventReviewsController` ainda carregava.
        AppAnimatedSwitcher(
          child: switch (status) {
            EventReviewsInitial() ||
            EventReviewsLoading() => const LoadingIndicator(
              key: ValueKey('reviews-loading'),
              size: 36,
            ),
            EventReviewsError(:final message) => Text(
              message,
              key: const ValueKey('reviews-error'),
              style: theme.textTheme.bodyMedium,
            ),
            EventReviewsEmpty() => Text(
              'Ninguém avaliou este rolê ainda.',
              key: const ValueKey('reviews-empty'),
              style: theme.textTheme.bodyMedium,
            ),
            EventReviewsLoaded(:final reviews) => Column(
              key: const ValueKey('reviews-loaded'),
              children: reviews.indexed
                  .map(
                    (entry) => AppStaggeredListItem(
                      index: entry.$1,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ProfileAvatar(
                          avatarPath: entry.$2.avatarUrl,
                          radius: 20,
                        ),
                        title: Text(entry.$2.fullName ?? ''),
                        // FASE B0: a foto opcional da FASE A2 não tinha,
                        // até agora, nenhuma tela que a exibisse para
                        // outros membros do grupo - miniatura abaixo do
                        // comentário, nunca substituindo o avatar de
                        // quem avaliou (continua sendo a informação
                        // primária da linha). Fica no `subtitle` (não
                        // em `trailing`, orçamento de largura apertado
                        // ao lado do selo de nota) para não competir por
                        // espaço com o `AppBadge`.
                        subtitle:
                            (entry.$2.comment != null &&
                                    entry.$2.comment!.isNotEmpty) ||
                                entry.$2.photoUrl != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.$2.comment != null &&
                                      entry.$2.comment!.isNotEmpty)
                                    Text(entry.$2.comment!),
                                  if (entry.$2.photoUrl != null) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    ClipRRect(
                                      borderRadius: AppRadius.radiusSm,
                                      child: Image.network(
                                        entry.$2.photoUrl!,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : null,
                        trailing: AppBadge(
                          label: entry.$2.averageScore.toStringAsFixed(1),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          },
        ),
        if (canReview) ...[
          const SizedBox(height: AppSpacing.md),
          AppOutlinedButton(
            label: ownReview == null ? 'Avaliar rolê' : 'Editar avaliação',
            onPressed: () => _openReviewForm(context, ref, ownReview),
          ),
        ],
      ],
    );
  }
}
