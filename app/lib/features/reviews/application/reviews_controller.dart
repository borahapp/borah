import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../data/review_repository_impl.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import '../presentation/states/reviews_status.dart';

/// Fluxo simples ReviewRepository -> Controller (mesmo padrão do
/// DV-01/DV-02/DV-03), sem use cases intermediários. Responsável apenas
/// pela listagem paginada de avaliações de um restaurante - o controller
/// nunca constrói consulta PostgREST (isso fica em `data/`).
class ReviewsController extends Notifier<ReviewsStatus> {
  @override
  ReviewsStatus build() => const ReviewsInitial();

  ReviewRepository get _repository => ref.read(reviewRepositoryProvider);

  String? _restaurantId;
  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> loadForRestaurant(String restaurantId) {
    _restaurantId = restaurantId;
    _page = 1;
    return _run(const ReviewsLoading(), requestId: ++_requestId);
  }

  /// Remove [reviewId] da lista já carregada, sem nova consulta ao
  /// backend (2B.3 - P1) - chamado por `ReviewDetailController.delete()`
  /// para refletir a exclusão aqui sem exigir refresh manual. Sem efeito
  /// se a lista ainda não estiver carregada ou não contiver [reviewId]
  /// (ex.: usuário nunca visitou esta tela).
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
    if (_restaurantId == null ||
        current is! ReviewsLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `FeedController._run`): só a resposta cujo `requestId` ainda bate com
  /// `_requestId` no momento em que o fetch resolve pode escrever em
  /// `state` - evita que um `loadNextPage` disparado durante um
  /// `loadForRestaurant` (ou vice-versa) produza um resultado final
  /// inconsistente, qualquer que seja a ordem em que as respostas cheguem.
  Future<void> _run(
    ReviewsStatus loadingState, {
    List<Review> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listByRestaurant(
        _restaurantId!,
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const ReviewsEmpty()
          : ReviewsLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on ReviewRepositoryException catch (e) {
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
      state = ReviewsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const ReviewsError('Não foi possível carregar as avaliações.');
    }
  }
}

final reviewsControllerProvider =
    NotifierProvider<ReviewsController, ReviewsStatus>(ReviewsController.new);
