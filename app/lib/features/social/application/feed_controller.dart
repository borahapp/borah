import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../../reviews/domain/review.dart';
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
  int _requestId = 0;
  static const _limit = 20;

  Future<void> loadForUser(String userId) {
    _userId = userId;
    _page = 1;
    return _run(const FeedLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! FeedLoaded ||
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

  /// Atualiza o feed já carregado sem esconder o resultado anterior
  /// (DV-07 §10 "Refreshing") - mesmo padrão do `FavoritesController.refresh`.
  Future<void> refresh() {
    if (_userId == null) return Future.value();
    final current = state;
    final refreshingState = current is FeedLoaded
        ? FeedRefreshing(current.result)
        : const FeedLoading();
    _page = 1;
    return _run(refreshingState, requestId: ++_requestId);
  }

  /// [previousItems] permite acumular páginas anteriores (Infinite Scroll,
  /// DV-07 §11) quando chamado por `loadNextPage` - vazio por padrão, para
  /// que `loadForUser`/`refresh` continuem substituindo a lista inteira.
  ///
  /// [requestId] coordena chamadas concorrentes: `loadNextPage`/`refresh`/
  /// `loadForUser` disparadas quase ao mesmo tempo (ex.: rolar até o fim
  /// enquanto um `refresh` ainda está em voo) capturam o valor de
  /// `_requestId` no início de cada chamada; só a resposta cujo
  /// `requestId` ainda bate com `_requestId` no momento em que o fetch
  /// resolve pode escrever em `state` - uma resposta mais antiga que chega
  /// depois de uma chamada mais nova já ter assumido é descartada
  /// silenciosamente, em vez de sobrescrever um resultado mais atual.
  Future<void> _run(
    FeedStatus loadingState, {
    List<Review> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listForUser(
        _userId!,
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const FeedEmpty()
          : FeedLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on FeedRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de substituí-la por um estado
      // de erro de tela cheia - só a falha do carregamento inicial (sem
      // nenhum item ainda) vira FeedError.
      if (previousItems.isNotEmpty) return;
      state = FeedError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) return;
      state = const FeedError('Não foi possível carregar o feed.');
    }
  }
}

final feedControllerProvider = NotifierProvider<FeedController, FeedStatus>(
  FeedController.new,
);
