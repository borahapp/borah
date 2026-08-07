import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  static const _limit = 20;

  Future<void> load() {
    _page = 1;
    return _run(const ModerationLoading());
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! ModerationLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(current, previousItems: current.result.items);
  }

  Future<void> hideComment(String commentId, {required String actorId}) {
    return _mutate(() async {
      await _commentRepository.hideAsAdmin(commentId);
      await _auditLogRepository.log(
        actorId: actorId,
        action: 'hide_comment',
        entity: 'comment',
        entityId: commentId,
      );
    });
  }

  Future<void> hideReview(String reviewId, {required String actorId}) {
    return _mutate(() async {
      await _reviewRepository.hideAsAdmin(reviewId);
      await _auditLogRepository.log(
        actorId: actorId,
        action: 'hide_review',
        entity: 'review',
        entityId: reviewId,
      );
    });
  }

  Future<void> _mutate(Future<void> Function() action) async {
    final current = state;
    if (current is ModerationLoaded) {
      state = ModerationProcessing(current.result);
    }
    try {
      await action();
      // Volta para a página 1: mesma simplificação de
      // `AdminRestaurantsController.updateStatus`.
      _page = 1;
      await _run(const ModerationLoading());
    } on CommentRepositoryException catch (e) {
      state = ModerationError(e.message);
    } on ReviewRepositoryException catch (e) {
      state = ModerationError(e.message);
    } catch (_) {
      state = const ModerationError('Não foi possível concluir a operação.');
    }
  }

  Future<void> _run(
    ModerationStatus loadingState, {
    List<CommentReport> previousItems = const [],
  }) async {
    state = loadingState;
    try {
      final result = await _commentRepository.listAllReports(
        page: _page,
        limit: _limit,
      );
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
      state = ModerationError(e.message);
    } catch (_) {
      state = const ModerationError('Não foi possível carregar as denúncias.');
    }
  }
}

final moderationControllerProvider =
    NotifierProvider<ModerationController, ModerationStatus>(
      ModerationController.new,
    );
