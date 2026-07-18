import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/review_repository_impl.dart';
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
  static const _limit = 20;

  Future<void> loadForRestaurant(String restaurantId) {
    _restaurantId = restaurantId;
    _page = 1;
    return _run(const ReviewsLoading());
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_restaurantId == null ||
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
      final result = await _repository.listByRestaurant(
        _restaurantId!,
        page: _page,
        limit: _limit,
      );
      state = result.items.isEmpty && _page == 1
          ? const ReviewsEmpty()
          : ReviewsLoaded(result);
    } on ReviewRepositoryException catch (e) {
      state = ReviewsError(e.message);
    } catch (_) {
      state = const ReviewsError('Não foi possível carregar as avaliações.');
    }
  }
}

final reviewsControllerProvider =
    NotifierProvider<ReviewsController, ReviewsStatus>(ReviewsController.new);
