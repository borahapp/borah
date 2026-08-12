import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../../reviews/data/review_repository_impl.dart';
import '../../reviews/domain/review_repository.dart';
import '../../reviews/presentation/states/reviews_status.dart';

/// Avaliações de um usuário específico (DV-07 - aba "avaliações" do
/// Perfil público). Reaproveita `ReviewsStatus` do DV-04 (mesma forma:
/// listagem paginada) - só muda a fonte da consulta (`listByUser` em vez
/// de `listByRestaurant`), mesmo padrão de reuso do `RankingsController`
/// com `RestaurantRepository`.
class UserReviewsController extends Notifier<ReviewsStatus> {
  @override
  ReviewsStatus build() => const ReviewsInitial();

  ReviewRepository get _repository => ref.read(reviewRepositoryProvider);

  String? _userId;
  int _page = 1;
  static const _limit = 20;

  Future<void> loadForUser(String userId) {
    _userId = userId;
    _page = 1;
    return _run(const ReviewsLoading());
  }

  /// Remove [reviewId] da lista já carregada, sem nova consulta ao
  /// backend (2B.3 - P1) - mesmo mecanismo de
  /// `ReviewsController.removeReview`, duplicado aqui por decisão
  /// consciente (os dois controllers não compartilham uma base comum
  /// hoje, mesma convenção já usada em outros pares do projeto).
  void removeReview(String reviewId) {
    final current = state;
    if (current is! ReviewsLoaded) return;
    final items = current.result.items
        .where((review) => review.id != reviewId)
        .toList();
    state = items.isEmpty
        ? const ReviewsEmpty()
        : ReviewsLoaded(
            PagedResult(
              items: items,
              page: current.result.page,
              limit: current.result.limit,
              hasNextPage: current.result.hasNextPage,
            ),
          );
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! ReviewsLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(current);
  }

  Future<void> _run(ReviewsStatus loadingState) async {
    state = loadingState;
    try {
      final result = await _repository.listByUser(
        _userId!,
        page: _page,
        limit: _limit,
      );
      state = result.items.isEmpty
          ? const ReviewsEmpty()
          : ReviewsLoaded(result);
    } on ReviewRepositoryException catch (e) {
      state = ReviewsError(e.message);
    } catch (_) {
      state = const ReviewsError('Não foi possível carregar as avaliações.');
    }
  }
}

final userReviewsControllerProvider =
    NotifierProvider<UserReviewsController, ReviewsStatus>(
      UserReviewsController.new,
    );
