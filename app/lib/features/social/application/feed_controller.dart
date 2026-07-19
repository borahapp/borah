import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feed_repository_impl.dart';
import '../domain/feed_repository.dart';
import '../presentation/states/feed_status.dart';

/// Fluxo simples FeedRepository -> Controller (mesmo padrão do DV-01 em
/// diante), sem use cases intermediários.
class FeedController extends Notifier<FeedStatus> {
  @override
  FeedStatus build() => const FeedInitial();

  FeedRepository get _repository => ref.read(feedRepositoryProvider);

  String? _userId;
  int _page = 1;
  static const _limit = 20;

  Future<void> loadForUser(String userId) {
    _userId = userId;
    _page = 1;
    return _run(const FeedLoading());
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! FeedLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(current);
  }

  /// Atualiza o feed já carregado sem esconder o resultado anterior
  /// (DV-07 §10 "Refreshing") - mesmo padrão do `FavoritesController.refresh`.
  Future<void> refresh() {
    if (_userId == null) return Future.value();
    final current = state;
    final refreshingState = current is FeedLoaded
        ? FeedRefreshing(current.result)
        : const FeedLoading();
    _page = 1;
    return _run(refreshingState);
  }

  Future<void> _run(FeedStatus loadingState) async {
    state = loadingState;
    try {
      final result = await _repository.listForUser(
        _userId!,
        page: _page,
        limit: _limit,
      );
      state = result.items.isEmpty ? const FeedEmpty() : FeedLoaded(result);
    } on FeedRepositoryException catch (e) {
      state = FeedError(e.message);
    } catch (_) {
      state = const FeedError('Não foi possível carregar o feed.');
    }
  }
}

final feedControllerProvider = NotifierProvider<FeedController, FeedStatus>(
  FeedController.new,
);
