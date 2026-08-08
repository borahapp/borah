import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/current_user_role_provider.dart';
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
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfAuthorized());
    _scrollController.addListener(_onScroll);
  }

  /// FASE C.2.1: segunda camada de defesa - sem isto, a carga inicial
  /// disparava antes de `AdminGuard` confirmar o papel do usuário (a RLS
  /// já protegia os dados, mas a consulta saía do cliente de qualquer
  /// forma). Reaproveita o mesmo `Future` que `AdminGuard` já observa
  /// (`currentUserRoleProvider` não é `autoDispose` - não gera uma
  /// segunda consulta de papel).
  Future<void> _loadIfAuthorized() async {
    final String? role;
    try {
      role = await ref.read(currentUserRoleProvider.future);
    } catch (_) {
      return;
    }
    if (!mounted || role == null) return;
    ref.read(moderationControllerProvider.notifier).load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _isLoadingMore = true;
    ref.read(moderationControllerProvider.notifier).loadNextPage().whenComplete(
      () {
        if (mounted) _isLoadingMore = false;
      },
    );
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
            controller: _scrollController,
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
