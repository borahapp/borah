import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../data/review_repository_impl.dart';
import '../domain/review_repository.dart';
import '../domain/reviewer_ranking_entry.dart';
import '../presentation/states/reviewer_ranking_status.dart';

/// Ranking de Avaliadores (rodada "perfil individual como centro", pós-
/// FASE 09, Item E) - mesmo padrão de paginação/concorrência de
/// `RankingUsersController` (DV-10), só que sobre `ReviewRepository` em
/// vez de `GamificationRepository`. Sem variante "Amigos" aqui - o Item
/// E pediu só o ranking global de quem mais avaliou restaurantes.
class ReviewerRankingController extends Notifier<ReviewerRankingStatus> {
  @override
  ReviewerRankingStatus build() => const ReviewerRankingInitial();

  ReviewRepository get _repository => ref.read(reviewRepositoryProvider);

  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> load() {
    _page = 1;
    return _run(const ReviewerRankingLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! ReviewerRankingLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  /// [requestId] coordena chamadas concorrentes - mesmo mecanismo de
  /// `RankingUsersController._run`.
  Future<void> _run(
    ReviewerRankingStatus loadingState, {
    List<ReviewerRankingEntry> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listTopReviewers(
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const ReviewerRankingEmpty()
          : ReviewerRankingLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on ReviewRepositoryException catch (e) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = ReviewerRankingError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const ReviewerRankingError(
        'Não foi possível carregar o ranking.',
      );
    }
  }
}

final reviewerRankingControllerProvider =
    NotifierProvider<ReviewerRankingController, ReviewerRankingStatus>(
      ReviewerRankingController.new,
    );
