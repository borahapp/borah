import '../../../../core/models/paged_result.dart';
import '../../domain/ranking_entry.dart';

/// Tipo de ranking (DV-10 §5: "Global" e "Entre amigos" - "Mensal" fora
/// de escopo, sem histórico temporal).
enum RankingUsersType { global, friends }

/// Estado do Ranking de Usuários (DV-10), sealed class.
sealed class RankingUsersStatus {
  const RankingUsersStatus();
}

final class RankingUsersInitial extends RankingUsersStatus {
  const RankingUsersInitial();
}

final class RankingUsersLoading extends RankingUsersStatus {
  const RankingUsersLoading();
}

final class RankingUsersLoaded extends RankingUsersStatus {
  const RankingUsersLoaded(this.result);

  final PagedResult<RankingEntry> result;
}

final class RankingUsersEmpty extends RankingUsersStatus {
  const RankingUsersEmpty();
}

final class RankingUsersError extends RankingUsersStatus {
  const RankingUsersError(this.message);

  final String message;
}
