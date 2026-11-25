import '../../../core/models/paged_result.dart';
import 'ranked_restaurant.dart';
import 'ranking_scope.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01/02/03/04) -
/// nenhuma camada acima de `data/` conhece exceções de outros módulos.
class RankingRepositoryException implements Exception {
  const RankingRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Rankings (DV-05, ampliado pelo Item F - ranking
/// multi-escopo). Não existe entidade física de Ranking nem tabela
/// própria - o resultado é sempre um [RankedRestaurant], nunca o
/// `Restaurant` do DV-03 (os 3 escopos têm fontes e campos de nota
/// diferentes - ver comentário de `RankedRestaurant`).
abstract interface class RankingRepository {
  /// [groupId] obrigatório quando [scope] é [RankingScope.group];
  /// [userId] obrigatório quando [scope] é [RankingScope.personal] - a
  /// camada de aplicação é quem garante isso (o controller só chama com
  /// o escopo selecionado e o dado que ele exige), nunca validado aqui.
  Future<PagedResult<RankedRestaurant>> list({
    required RankingScope scope,
    String? groupId,
    String? userId,
    String? city,
    String? state,
    String? country,
    String? category,
    required int page,
    required int limit,
  });
}
