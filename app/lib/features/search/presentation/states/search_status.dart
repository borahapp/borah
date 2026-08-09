import '../../../../core/models/paged_result.dart';
import '../../../restaurants/domain/restaurant.dart';
import '../../../users/domain/user_profile.dart';

/// Estado da tela de Pesquisa (FASE SOCIAL 1), sealed class - mesmo
/// padrão do resto do app. `SearchLoaded` carrega os 2 resultados que já
/// existem (Pessoas, Restaurantes) - Grupos não tem estado próprio
/// porque a busca de grupos públicos ainda não é possível (RLS de
/// `groups` bloqueia 100% de acesso a não-membros até `groups.visibility`
/// existir - fase futura, ver PLANO UX/TÉCNICO). A UI mostra uma seção
/// de Grupos fixa, explicativa, não um estado de carregamento real.
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
  const SearchLoaded({required this.people, required this.restaurants});

  final PagedResult<UserProfile> people;
  final PagedResult<Restaurant> restaurants;
}

final class SearchError extends SearchStatus {
  const SearchError(this.message);

  final String message;
}
