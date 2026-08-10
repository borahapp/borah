import '../../../../core/models/paged_result.dart';
import '../../../groups/domain/group.dart';
import '../../../restaurants/domain/restaurant.dart';
import '../../../users/domain/user_profile.dart';

/// Estado da tela de Pesquisa (FASE SOCIAL 1-3), sealed class - mesmo
/// padrão do resto do app. `SearchLoaded` carrega os 3 resultados
/// (Pessoas, Grupos, Restaurantes) - busca de grupos só ficou possível
/// a partir da FASE SOCIAL 3 (`groups.visibility`); antes disso a UI
/// mostrava uma mensagem fixa em vez de resultado real.
sealed class SearchStatus {
  const SearchStatus();
}

/// Nenhuma busca feita ainda (campo vazio).
final class SearchInitial extends SearchStatus {
  const SearchInitial();
}

final class SearchLoading extends SearchStatus {
  const SearchLoading();
}

final class SearchLoaded extends SearchStatus {
  const SearchLoaded({
    required this.people,
    required this.groups,
    required this.restaurants,
  });

  final PagedResult<UserProfile> people;
  final PagedResult<Group> groups;
  final PagedResult<Restaurant> restaurants;
}

final class SearchError extends SearchStatus {
  const SearchError(this.message);

  final String message;
}
