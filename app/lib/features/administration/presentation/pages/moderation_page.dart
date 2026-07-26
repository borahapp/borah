import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/moderation_controller.dart';
import '../states/moderation_status.dart';
import '../widgets/admin_guard.dart';

/// Moderação de Denúncias (DV-08 §6): fila de `comment_reports`, com ação
/// de ocultar o comentário denunciado. Moderação direta de avaliações
/// (sem denúncia associada) fica disponível na tela de Detalhes da
/// avaliação para quem tem papel administrativo (ver nota no botão).
class ModerationPage extends ConsumerStatefulWidget {
  const ModerationPage({super.key});

  @override
  ConsumerState<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends ConsumerState<ModerationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moderationControllerProvider.notifier).load();
    });
  }

  void _hideComment(String commentId) {
    final actorId = ref.read(currentUserIdProvider);
    if (actorId == null) return;
    ref
        .read(moderationControllerProvider.notifier)
        .hideComment(commentId, actorId: actorId);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(moderationControllerProvider);

    return AdminGuard(
      child: Scaffold(
        appBar: const AppTopBar(title: 'Denúncias'),
        body: switch (status) {
          ModerationInitial() || ModerationLoading() => const LoadingScreen(),
          ModerationError(:final message) => ErrorState(
            message: message,
            onRetry: () =>
                ref.read(moderationControllerProvider.notifier).load(),
          ),
          ModerationEmpty() => const EmptyState(
            message: 'Nenhuma denúncia pendente.',
          ),
          ModerationProcessing(:final result) ||
          ModerationLoaded(:final result) => ListView.builder(
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final report = result.items[index];
              return ListTile(
                title: Text(report.reason),
                subtitle: Text('Comentário: ${report.commentId}'),
                trailing: AppTextButton(
                  label: 'Ocultar comentário',
                  onPressed: () => _hideComment(report.commentId),
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
