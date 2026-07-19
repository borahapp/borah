import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/comment_repository_impl.dart';
import '../domain/comment_repository.dart';
import '../presentation/states/comments_status.dart';

/// Fluxo simples CommentRepository -> Controller (mesmo padrão do DV-01
/// em diante), sem use cases intermediários. Cobre listar/criar/editar/
/// excluir/denunciar comentários de UMA avaliação (não há tela de
/// "detalhes do comentário" separada - DV-07 §6 lista "Comentários" como
/// uma única tela).
class CommentsController extends Notifier<CommentsStatus> {
  @override
  CommentsStatus build() => const CommentsInitial();

  CommentRepository get _repository => ref.read(commentRepositoryProvider);

  String? _reviewId;
  int _page = 1;
  static const _limit = 20;

  Future<void> loadForReview(String reviewId) {
    _reviewId = reviewId;
    _page = 1;
    return _run(const CommentsLoading());
  }

  Future<void> create({required String userId, required String content}) {
    if (_reviewId == null) return Future.value();
    return _mutate(
      () => _repository.create(
        reviewId: _reviewId!,
        userId: userId,
        content: content,
      ),
    );
  }

  /// Sujeito à janela de edição de 15 minutos (reforçada no banco) - uma
  /// tentativa fora do prazo chega como `CommentsError`.
  Future<void> update(String commentId, {required String content}) {
    return _mutate(() => _repository.update(commentId, content: content));
  }

  Future<void> delete(String commentId) {
    return _mutate(() => _repository.delete(commentId));
  }

  Future<void> report(
    String commentId, {
    required String reportedBy,
    required String reason,
  }) {
    return _mutate(
      () =>
          _repository.report(commentId, reportedBy: reportedBy, reason: reason),
    );
  }

  /// Executa uma mutação (criar/editar/excluir/denunciar) mostrando
  /// `CommentsPublishing` sobre a lista já carregada, e recarrega a
  /// primeira página ao final - mais simples do que atualizar a lista
  /// localmente item a item.
  Future<void> _mutate(Future<void> Function() action) async {
    final current = state;
    final publishingState = current is CommentsLoaded
        ? CommentsPublishing(current.result)
        : const CommentsLoading();
    state = publishingState;
    try {
      await action();
      _page = 1;
      await _run(publishingState);
    } on CommentRepositoryException catch (e) {
      state = CommentsError(e.message);
    } catch (_) {
      state = const CommentsError('Não foi possível concluir a operação.');
    }
  }

  Future<void> _run(CommentsStatus loadingState) async {
    if (_reviewId == null) return;
    state = loadingState;
    try {
      final result = await _repository.listByReview(
        _reviewId!,
        page: _page,
        limit: _limit,
      );
      state = result.items.isEmpty
          ? const CommentsEmpty()
          : CommentsLoaded(result);
    } on CommentRepositoryException catch (e) {
      state = CommentsError(e.message);
    } catch (_) {
      state = const CommentsError('Não foi possível carregar os comentários.');
    }
  }
}

final commentsControllerProvider =
    NotifierProvider<CommentsController, CommentsStatus>(
      CommentsController.new,
    );
