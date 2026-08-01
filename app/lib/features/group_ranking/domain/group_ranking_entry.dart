/// Uma linha do ranking do grupo (BLOCO 5) - dados vêm de
/// `group_members` (`events_count`/`reviews_count`/`average_score`,
/// mantidos por trigger) + `profiles` (`fullName`/`avatarUrl`), mesma
/// limitação de `GroupMember` (sem FK direta entre as duas tabelas).
class GroupRankingEntry {
  const GroupRankingEntry({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,

    /// Rolês com presença confirmada, dentro deste grupo - critério
    /// primário de ordenação (ver decisão registrada na migration
    /// `20260801110000_add_group_ranking_columns.sql`).
    required this.eventsCount,

    /// Quantidade de avaliações coletivas que este membro enviou.
    required this.reviewsCount,

    /// Nota média que o PRÓPRIO membro deu em suas avaliações (não a
    /// nota dos restaurantes que organizou) - `null` até a primeira
    /// avaliação.
    required this.averageScore,
  });

  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final int eventsCount;
  final int reviewsCount;
  final double? averageScore;
}
