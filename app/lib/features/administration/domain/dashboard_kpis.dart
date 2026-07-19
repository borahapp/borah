/// Indicadores do Dashboard (DV-08 §6) - contagens simples, sem tabela
/// própria. "Denúncias pendentes" é o total de `comment_reports`: o
/// modelo do DV-07 não tem coluna de status (resolvida/pendente), então
/// não há como distinguir denúncias já tratadas - simplificação
/// registrada, consistente com "sem workflow de moderação" do DV-07.
class DashboardKpis {
  const DashboardKpis({
    required this.usersCount,
    required this.restaurantsCount,
    required this.reviewsCount,
    required this.pendingReportsCount,
  });

  final int usersCount;
  final int restaurantsCount;
  final int reviewsCount;
  final int pendingReportsCount;
}
