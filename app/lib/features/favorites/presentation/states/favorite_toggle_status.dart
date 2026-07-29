/// Estado do favoritar/desfavoritar de um restaurante específico (DV-06
/// §5) - separado de `FavoritesStatus` (listagem), assim como o
/// `RestaurantDetailStatus` é separado de `RestaurantsStatus` no DV-03.
sealed class FavoriteToggleStatus {
  const FavoriteToggleStatus();
}

final class FavoriteToggleInitial extends FavoriteToggleStatus {
  const FavoriteToggleInitial();
}

final class FavoriteToggleLoading extends FavoriteToggleStatus {
  const FavoriteToggleLoading();
}

final class FavoriteToggleLoaded extends FavoriteToggleStatus {
  const FavoriteToggleLoaded(this.isFavorited);

  final bool isFavorited;
}

/// Carrega o valor revertido (`isFavorited`) junto do erro, para que a UI
/// sempre saiba o estado real do ícone após o rollback da atualização
/// otimista (DV-06 decisão 5) - a UI não decide a reversão, só exibe o
/// que o controller já reverteu.
final class FavoriteToggleError extends FavoriteToggleStatus {
  const FavoriteToggleError(this.message, this.isFavorited);

  final String message;
  final bool isFavorited;
}
