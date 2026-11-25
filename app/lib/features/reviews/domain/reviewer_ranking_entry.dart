/// Uma linha do Ranking de Avaliadores (rodada "perfil individual como
/// centro", pós-FASE 09, Item E) - quem mais avaliou restaurantes.
/// `fullName` nulo indica perfil sem nome preenchido (mesma tolerância já
/// usada em `RankingEntry`/`FollowerRepositoryImpl`).
class ReviewerRankingEntry {
  const ReviewerRankingEntry({
    required this.userId,
    this.fullName,
    required this.reviewsCount,
  });

  final String userId;
  final String? fullName;
  final int reviewsCount;
}
