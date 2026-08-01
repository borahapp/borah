import 'group_ranking_entry.dart';

/// Erro traduzido pela camada de dados - mesmo padrão de
/// `GroupRepositoryException`/`EventRepositoryException` (nenhuma
/// classe base comum entre features).
class GroupRankingRepositoryException implements Exception {
  const GroupRankingRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio, independente de Flutter e Supabase (AR-02).
/// Sem paginação - mesma decisão de `GroupRepository.getById` (membros
/// de um grupo não paginam neste projeto; grupos são pequenos).
abstract interface class GroupRankingRepository {
  /// Ordenado por `eventsCount` desc, `reviewsCount` desc (mesmo
  /// critério de desempate em cadeia de `FavoriteSortBy.rating`) -
  /// ordenação real fica na consulta (`ORDER BY` direto nas colunas
  /// denormalizadas de `group_members`), não recalculada aqui.
  Future<List<GroupRankingEntry>> listByGroup(String groupId);
}
