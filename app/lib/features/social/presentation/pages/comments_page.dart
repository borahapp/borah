import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/comments_controller.dart';
import '../states/comments_status.dart';

/// Tela de Comentários de uma avaliação (DV-07 §6). Denúncia (decisão 4)
/// registra apenas o motivo, sem workflow de moderação.
class CommentsPage extends ConsumerStatefulWidget {
  const CommentsPage({super.key, required this.reviewId});

  final String reviewId;

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage> {
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(commentsControllerProvider.notifier)
          .loadForReview(widget.reviewId);
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    ref
        .read(commentsControllerProvider.notifier)
        .create(userId: userId, content: content);
    _contentController.clear();
  }

  Future<void> _report(String commentId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _ReportDialog(),
    );
    if (reason == null || reason.isEmpty) return;

    await ref
        .read(commentsControllerProvider.notifier)
        .report(commentId, reportedBy: userId, reason: reason);
  }

  void _delete(String commentId) {
    ref.read(commentsControllerProvider.notifier).delete(commentId);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(commentsControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    ref.listen<CommentsStatus>(commentsControllerProvider, (previous, next) {
      if (next is CommentsError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Comentários')),
      body: Column(
        children: [
          Expanded(
            child: switch (status) {
              CommentsInitial() || CommentsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              CommentsError(:final message) => Center(child: Text(message)),
              CommentsEmpty() => const Center(
                child: Text('Nenhum comentário ainda.'),
              ),
              CommentsPublishing(:final result) ||
              CommentsLoaded(:final result) => ListView.builder(
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final comment = result.items[index];
                  final isOwn = comment.userId == currentUserId;
                  return ListTile(
                    title: Text(comment.content),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') _delete(comment.id);
                        if (value == 'report') _report(comment.id);
                      },
                      itemBuilder: (context) => [
                        if (isOwn)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir'),
                          ),
                        if (!isOwn)
                          const PopupMenuItem(
                            value: 'report',
                            child: Text('Denunciar'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _contentController,
                      label: 'Escreva um comentário',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.send), onPressed: _submit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Denunciar comentário'),
      content: AppTextField(controller: _reasonController, label: 'Motivo'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppPrimaryButton(
          label: 'Denunciar',
          onPressed: () =>
              Navigator.of(context).pop(_reasonController.text.trim()),
        ),
      ],
    );
  }
}
