import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../../restaurants/domain/restaurant.dart';
import '../data/favorite_repository_impl.dart';
import '../domain/favorite_repository.dart';
import '../domain/favorite_sort_by.dart';
import '../presentation/states/favorites_status.dart';

/// Fluxo simples FavoriteRepository -> Controller (mesmo padrão do
/// DV-01 em diante), sem use cases intermediários. Responsável apenas
/// pela listagem paginada de favoritos do usuário - busca, cidade,
/// categoria e ordenação (DV-06 §5) são todos parâmetros do mesmo
/// `loadForUser`, sem métodos separados por filtro.
class FavoritesController extends Notifier<FavoritesStatus> {
  @override
  FavoritesStatus build() => const FavoritesInitial();

  FavoriteRepository get _repository => ref.read(favoriteRepositoryProvider);

  String? _userId;
  String? _query;
  String? _city;
  String? _category;
  FavoriteSortBy _sortBy = FavoriteSortBy.date;
  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> loadForUser(
    String userId, {
    String? query,
    String? city,
    String? category,
    FavoriteSortBy sortBy = FavoriteSortBy.date,
  }) {
    _userId = userId;
    _query = query;
    _city = city;
    _category = category;
    _sortBy = sortBy;
    _page = 1;
    return _run(const FavoritesLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! FavoritesLoaded ||
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

  /// Atualiza a lista já carregada sem esconder o resultado anterior
  /// (DV-06 §10 "Syncing" / §11 "Persistência em tempo real").
  Future<void> refresh() {
    if (_userId == null) return Future.value();
    final current = state;
    final syncingState = current is FavoritesLoaded
        ? FavoritesSyncing(current.result)
        : const FavoritesLoading();
    _page = 1;
    return _run(syncingState, requestId: ++_requestId);
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `FeedController._run`): só a resposta cujo `requestId` ainda bate com
  /// `_requestId` no momento em que o fetch resolve pode escrever em
  /// `state` - evita que um `loadNextPage` e um `refresh` disparados quase
  /// ao mesmo tempo produzam um resultado final inconsistente, qualquer
  /// que seja a ordem em que as respostas cheguem.
  Future<void> _run(
    FavoritesStatus loadingState, {
    List<Restaurant> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listForUser(
        _userId!,
        query: _query,
        city: _city,
        category: _category,
        sortBy: _sortBy,
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const FavoritesEmpty()
          : FavoritesLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on FavoriteRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      if (previousItems.isNotEmpty) return;
      state = FavoritesError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) return;
      state = const FavoritesError('Não foi possível carregar os favoritos.');
    }
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, FavoritesStatus>(
      FavoritesController.new,
    );
