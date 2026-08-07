/// Resumo agregado da atividade do usuário em Grupos/Rolês, somado
/// entre TODOS os grupos que participa - diferente de
/// `GroupRankingEntry` (que é escopado a um único grupo), este valor
/// não pertence a nenhum grupo específico.
///
/// FASE B, Entrega 4: alimenta a seção "XP de rolês" em
/// `gamification_profile_page.dart`. Fonte: soma das mesmas colunas
/// denormalizadas de `group_members` que `GroupRankingEntry` já usa
/// (`events_count`/`reviews_count`, mantidas por trigger desde o BLOCO
/// 5), só sem o filtro por `group_id` - nenhuma tabela ou coluna nova.
class GroupsActivitySummary {
  const GroupsActivitySummary({
    required this.eventsCount,
    required this.reviewsCount,
  });

  /// Total de rolês com presença confirmada, somado entre todos os
  /// grupos do usuário.
  final int eventsCount;

  /// Total de avaliações coletivas enviadas, somado entre todos os
  /// grupos do usuário.
  final int reviewsCount;
}
