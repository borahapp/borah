import '../../../core/models/paged_result.dart';
import '../../reviews/domain/review.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class FeedRepositoryException implements Exception {
  const FeedRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Feed (DV-07 §5, escopo restrito à decisão
/// aprovada): apenas avaliações recentes de usuários seguidos. Reaproveita
/// `Review` (DV-04) - sem entidade própria. Favoritos e conquistas de
/// gamificação ficam fora desta versão (decisão do DV-07).
abstract interface class FeedRepository {
  Future<PagedResult<Review>> listForUser(
    String userId, {
    required int page,
    required int limit,
  });
}
