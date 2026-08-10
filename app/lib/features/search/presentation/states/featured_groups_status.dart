import '../../../groups/domain/group.dart';

/// Estado de "Grupos em destaque" (FASE SOCIAL 3, Pesquisa/Explorar) -
/// mesmo formato de `DiscoveryStatus`.
sealed class FeaturedGroupsStatus {
  const FeaturedGroupsStatus();
}

final class FeaturedGroupsInitial extends FeaturedGroupsStatus {
  const FeaturedGroupsInitial();
}

final class FeaturedGroupsLoading extends FeaturedGroupsStatus {
  const FeaturedGroupsLoading();
}

final class FeaturedGroupsLoaded extends FeaturedGroupsStatus {
  const FeaturedGroupsLoaded(this.groups, {required this.hasMore});

  final List<Group> groups;
  final bool hasMore;
}

final class FeaturedGroupsEmpty extends FeaturedGroupsStatus {
  const FeaturedGroupsEmpty();
}

final class FeaturedGroupsError extends FeaturedGroupsStatus {
  const FeaturedGroupsError(this.message);

  final String message;
}
