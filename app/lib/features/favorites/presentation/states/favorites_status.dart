import '../../../../core/models/paged_result.dart';
import '../../../restaurants/domain/restaurant.dart';

/// Estado da listagem de favoritos (DV-06 §10), sealed class. Prefixo
/// `Favorites*` para evitar colisão com estados de outros módulos (mesma
/// lição do DV-01 em diante).
sealed class FavoritesStatus {
  const FavoritesStatus();
}

final class FavoritesInitial extends FavoritesStatus {
  const FavoritesInitial();
}

final class FavoritesLoading extends FavoritesStatus {
  const FavoritesLoading();
}

final class FavoritesLoaded extends FavoritesStatus {
  const FavoritesLoaded(this.result);

  final PagedResult<Restaurant> result;
}

/// Atualização em segundo plano de uma lista já carregada (ex.: puxar
/// para atualizar) - mantém o resultado anterior visível em vez de
/// mostrar um spinner de tela cheia (DV-06 §10/§11).
final class FavoritesSyncing extends FavoritesStatus {
  const FavoritesSyncing(this.result);

  final PagedResult<Restaurant> result;
}

final class FavoritesEmpty extends FavoritesStatus {
  const FavoritesEmpty();
}

final class FavoritesError extends FavoritesStatus {
  const FavoritesError(this.message);

  final String message;
}
