import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        appBar: AppBar(title: const Text('Denúncias')),
        body: switch (status) {
          ModerationInitial() || ModerationLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ModerationError(:final message) => Center(child: Text(message)),
          ModerationEmpty() => const Center(
            child: Text('Nenhuma denúncia pendente.'),
          ),
          ModerationProcessing(:final result) ||
          ModerationLoaded(:final result) => ListView.builder(
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final report = result.items[index];
              return ListTile(
                title: Text(report.reason),
                subtitle: Text('Comentário: ${report.commentId}'),
                trailing: TextButton(
                  onPressed: () => _hideComment(report.commentId),
                  child: const Text('Ocultar comentário'),
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
