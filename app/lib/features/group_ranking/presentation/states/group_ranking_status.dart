import '../../domain/group_ranking_entry.dart';

/// Estado do ranking do grupo (BLOCO 5), sealed class - mesmo padrão de
/// `GroupsListStatus`/`EventsListStatus`.
sealed class GroupRankingStatus {
  const GroupRankingStatus();
}

final class GroupRankingInitial extends GroupRankingStatus {
  const GroupRankingInitial();
}

final class GroupRankingLoading extends GroupRankingStatus {
  const GroupRankingLoading();
}

final class GroupRankingLoaded extends GroupRankingStatus {
  const GroupRankingLoaded(this.entries);

  final List<GroupRankingEntry> entries;
}

final class GroupRankingError extends GroupRankingStatus {
  const GroupRankingError(this.message);

  final String message;
}
