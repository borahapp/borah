import '../../domain/group.dart';

/// Estado da listagem de "meus grupos" (GROUP-02B.0), sealed class -
/// mesmo shape de `FavoritesStatus`/`AdminRestaurantsStatus`. Sem
/// paginação (diferente de Favorites/Restaurants) - `listMine()` não
/// pagina, fora do escopo desta sprint.
sealed class GroupsListStatus {
  const GroupsListStatus();
}

final class GroupsListInitial extends GroupsListStatus {
  const GroupsListInitial();
}

final class GroupsListLoading extends GroupsListStatus {
  const GroupsListLoading();
}

final class GroupsListLoaded extends GroupsListStatus {
  const GroupsListLoaded(this.groups);

  final List<Group> groups;
}

final class GroupsListEmpty extends GroupsListStatus {
  const GroupsListEmpty();
}

final class GroupsListError extends GroupsListStatus {
  const GroupsListError(this.message);

  final String message;
}
