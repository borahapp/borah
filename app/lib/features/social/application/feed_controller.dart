import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../data/feed_repository_impl.dart';
import '../domain/feed_item.dart';
import '../domain/feed_repository.dart';
import '../presentation/states/feed_status.dart';

/// Lógica compartilhada pelas 2 abas do Feed (FASE SOCIAL 4 - "Para Você"/
/// "Seguindo") - só a fonte de dados ([fetchPage]) muda entre elas; toda a
/// paginação, concorrência e tratamento de erro é idêntica (mesmo padrão
/// já usado pelos ~12 controllers paginados do projeto).
abstract class FeedControllerBase extends Notifier<FeedStatus> {
  @override
  FeedStatus build() => const FeedInitial();

  FeedRepository get _repository => ref.read(feedRepositoryProvider);

  /// Busca uma página de itens desta aba. Implementado por cada subclasse
  /// (`listForYou`/`listFollowing`).
  Future<PagedResult<FeedItem>> fetchPage(
    String userId, {
    required int page,
    required int limit,
  });

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

  /// [previousItems] permite acumular páginas anteriores (Infinite Scroll)
  /// quando chamado por `loadNextPage` - vazio por padrão, para que
  /// `loadForUser`/`refresh` continuem substituindo a lista inteira.
  ///
  /// [requestId] coordena chamadas concorrentes: só a resposta cujo
  /// `requestId` ainda bate com `_requestId` no momento em que o fetch
  /// resolve pode escrever em `state` - uma resposta mais antiga que chega
  /// depois de uma chamada mais nova já ter assumido é descartada.
  Future<void> _run(
    FeedStatus loadingState, {
    List<FeedItem> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await fetchPage(_userId!, page: _page, limit: _limit);
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
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém a
      // lista já carregada visível em vez de substituí-la por um estado de
      // erro de tela cheia - só a falha do carregamento inicial vira
      // FeedError. Reverte `_page`: a página que falhou nunca chegou a ser
      // aplicada, então a próxima tentativa deve rebuscá-la.
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = FeedError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const FeedError('Não foi possível carregar o feed.');
    }
  }
}

/// Aba "Para Você" - descoberta determinística (seguidos + pessoas de
/// grupos em comum + entradas em grupos públicos), sem preenchimento com
/// conteúdo de qualquer usuário da plataforma.
class FeedForYouController extends FeedControllerBase {
  @override
  Future<PagedResult<FeedItem>> fetchPage(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _repository.listForYou(userId, page: page, limit: limit);
  }
}

/// Aba "Seguindo" - só avaliações e badges de quem o usuário segue.
class FeedFollowingController extends FeedControllerBase {
  @override
  Future<PagedResult<FeedItem>> fetchPage(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _repository.listFollowing(userId, page: page, limit: limit);
  }
}

final feedForYouControllerProvider =
    NotifierProvider<FeedForYouController, FeedStatus>(
      FeedForYouController.new,
    );

final feedFollowingControllerProvider =
    NotifierProvider<FeedFollowingController, FeedStatus>(
      FeedFollowingController.new,
    );
