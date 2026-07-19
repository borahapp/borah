import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/favorite_repository_impl.dart';
import '../domain/favorite_repository.dart';
import '../presentation/states/favorite_toggle_status.dart';

/// Favoritar/desfavoritar um restaurante específico (DV-06 §5), usado
/// pela tela de Detalhes do restaurante. Responsável pela atualização
/// otimista e pelo rollback em caso de falha - a UI só exibe o estado
/// atual, nunca decide reverter nada (decisão 5 do DV-06).
class FavoriteToggleController extends Notifier<FavoriteToggleStatus> {
  @override
  FavoriteToggleStatus build() => const FavoriteToggleInitial();

  FavoriteRepository get _repository => ref.read(favoriteRepositoryProvider);

  Future<void> load(String userId, String restaurantId) async {
    state = const FavoriteToggleLoading();
    try {
      final isFavorited = await _repository.isFavorited(userId, restaurantId);
      state = FavoriteToggleLoaded(isFavorited);
    } on FavoriteRepositoryException catch (e) {
      state = FavoriteToggleError(e.message, false);
    } catch (_) {
      state = const FavoriteToggleError(
        'Não foi possível verificar o favorito.',
        false,
      );
    }
  }

  Future<void> toggle(String userId, String restaurantId) async {
    final current = state;
    final wasFavorited = switch (current) {
      FavoriteToggleLoaded(:final isFavorited) => isFavorited,
      FavoriteToggleError(:final isFavorited) => isFavorited,
      _ => false,
    };

    final optimisticValue = !wasFavorited;
    state = FavoriteToggleLoaded(optimisticValue);

    try {
      if (optimisticValue) {
        await _repository.addFavorite(userId, restaurantId);
      } else {
        await _repository.removeFavorite(userId, restaurantId);
      }
    } on FavoriteRepositoryException catch (e) {
      state = FavoriteToggleError(e.message, wasFavorited);
    } catch (_) {
      state = FavoriteToggleError(
        'Não foi possível atualizar o favorito.',
        wasFavorited,
      );
    }
  }
}

final favoriteToggleControllerProvider =
    NotifierProvider<FavoriteToggleController, FavoriteToggleStatus>(
      FavoriteToggleController.new,
    );
