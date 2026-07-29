import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return _run(const FavoritesLoading());
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! FavoritesLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(current);
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
    return _run(syncingState);
  }

  Future<void> _run(FavoritesStatus loadingState) async {
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
      state = result.items.isEmpty
          ? const FavoritesEmpty()
          : FavoritesLoaded(result);
    } on FavoriteRepositoryException catch (e) {
      state = FavoritesError(e.message);
    } catch (_) {
      state = const FavoritesError('Não foi possível carregar os favoritos.');
    }
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, FavoritesStatus>(
      FavoritesController.new,
    );
