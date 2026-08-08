import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/paged_result.dart';
import '../../reviews/data/review_repository_impl.dart';
import '../../reviews/domain/review_repository.dart';
import '../../social/data/comment_repository_impl.dart';
import '../../social/domain/comment_report.dart';
import '../../social/domain/comment_repository.dart';
import '../data/audit_log_repository_impl.dart';
import '../domain/audit_log_repository.dart';
import '../presentation/states/moderation_status.dart';

/// Moderação (DV-08 §6): fila de denúncias de comentários e ocultação
/// direta de avaliações/comentários. Fotos fora de escopo (sem fila de
/// denúncia própria - decisão do DV-08).
class ModerationController extends Notifier<ModerationStatus> {
  @override
  ModerationStatus build() => const ModerationInitial();

  CommentRepository get _commentRepository =>
      ref.read(commentRepositoryProvider);
  ReviewRepository get _reviewRepository => ref.read(reviewRepositoryProvider);
  AuditLogRepository get _auditLogRepository =>
      ref.read(auditLogRepositoryProvider);

  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> load() {
    _page = 1;
    return _run(const ModerationLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! ModerationLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  Future<void> hideComment(String commentId, {required String actorId}) {
    return _mutate(() async {
      await _commentRepository.hideAsAdmin(commentId);
      try {
        await _auditLogRepository.log(
          actorId: actorId,
          action: 'hide_comment',
          entity: 'comment',
          entityId: commentId,
        );
      } catch (e, stackTrace) {
        // FASE C.2.2: best-effort - ver
        // AdminRestaurantsController.updateStatus para o racional
        // completo.
        AppLogger.warning(
          'Falha ao registrar auditoria de ocultação de comentário.',
          tag: 'administration/ModerationController.hideComment',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> hideReview(String reviewId, {required String actorId}) {
    return _mutate(() async {
      await _reviewRepository.hideAsAdmin(reviewId);
      try {
        await _auditLogRepository.log(
          actorId: actorId,
          action: 'hide_review',
          entity: 'review',
          entityId: reviewId,
        );
      } catch (e, stackTrace) {
        // FASE C.2.2: best-effort - ver
        // AdminRestaurantsController.updateStatus para o racional
        // completo.
        AppLogger.warning(
          'Falha ao registrar auditoria de ocultação de avaliação.',
          tag: 'administration/ModerationController.hideReview',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> _mutate(Future<void> Function() action) async {
    // Reivindica a geração antes de qualquer `await` (mesmo mecanismo de
    // `AdminRestaurantsController.updateStatus`).
    final requestId = ++_requestId;
    final current = state;
    if (current is ModerationLoaded) {
      state = ModerationProcessing(current.result);
    }
    try {
      await action();
      if (requestId != _requestId) return;
      // Volta para a página 1: mesma simplificação de
      // `AdminRestaurantsController.updateStatus`.
      _page = 1;
      await _run(const ModerationLoading(), requestId: requestId);
    } on CommentRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = ModerationError(e.message);
    } on ReviewRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = ModerationError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = const ModerationError('Não foi possível concluir a operação.');
    }
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `AdminRestaurantsController._run`).
  Future<void> _run(
    ModerationStatus loadingState, {
    List<CommentReport> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _commentRepository.listAllReports(
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const ModerationEmpty()
          : ModerationLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on CommentRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      // Reverte `_page`: a página que falhou nunca chegou a ser aplicada,
      // então a próxima tentativa deve rebuscá-la, em vez de pular para a
      // seguinte.
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = ModerationError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const ModerationError('Não foi possível carregar as denúncias.');
    }
  }
}

final moderationControllerProvider =
    NotifierProvider<ModerationController, ModerationStatus>(
      ModerationController.new,
    );
