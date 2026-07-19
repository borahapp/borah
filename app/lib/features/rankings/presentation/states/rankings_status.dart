import '../../../../core/models/paged_result.dart';
import '../../../restaurants/domain/restaurant.dart';

/// Estado da listagem de ranking (DV-05 §11), sealed class. Prefixo
/// `Rankings*` para evitar colisão com estados de outros módulos (mesma
/// lição do DV-01/02/03/04).
sealed class RankingsStatus {
  const RankingsStatus();
}

final class RankingsInitial extends RankingsStatus {
  const RankingsInitial();
}

final class RankingsLoading extends RankingsStatus {
  const RankingsLoading();
}

final class RankingsLoaded extends RankingsStatus {
  const RankingsLoaded(this.result);

  final PagedResult<Restaurant> result;
}

final class RankingsEmpty extends RankingsStatus {
  const RankingsEmpty();
}

final class RankingsError extends RankingsStatus {
  const RankingsError(this.message);

  final String message;
}
