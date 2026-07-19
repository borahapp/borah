import '../../../core/models/paged_result.dart';
import '../../restaurants/domain/restaurant.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01/02/03/04) -
/// nenhuma camada acima de `data/` conhece exceções de outros módulos.
class RankingRepositoryException implements Exception {
  const RankingRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Rankings (DV-05). Não existe entidade física de
/// Ranking nem tabela própria - o resultado é sempre um `Restaurant`
/// (mesma entidade do DV-03), ordenado por relevância. `RankingRepository`
/// existe como camada de isolamento própria do módulo (delega para
/// `RestaurantRepository` em `data/`), para permitir evoluções futuras
/// (cache, materialized view, ranking entre amigos, Edge Functions) sem
/// que o controller precise conhecer `RestaurantRepository` diretamente.
abstract interface class RankingRepository {
  Future<PagedResult<Restaurant>> listRanked({
    String? city,
    String? category,
    required int page,
    required int limit,
  });
}
