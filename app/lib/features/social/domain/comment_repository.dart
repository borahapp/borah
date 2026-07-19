import '../../../core/models/paged_result.dart';
import 'comment.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class CommentRepositoryException implements Exception {
  const CommentRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Comentários (DV-07). "Curtidas sociais" não tem
/// contrato próprio aqui - o requisito é atendido pelo `review_likes` já
/// implementado no DV-04 (decisão registrada na análise do DV-07).
abstract interface class CommentRepository {
  Future<PagedResult<Comment>> listByReview(
    String reviewId, {
    required int page,
    required int limit,
  });

  Future<Comment> create({
    required String reviewId,
    required String userId,
    required String content,
  });

  /// Sujeito à janela de edição de 15 minutos, reforçada no banco (RLS +
  /// trigger) - uma falha aqui após o prazo chega como
  /// `CommentRepositoryException`.
  Future<Comment> update(String id, {required String content});

  /// Exclusão lógica (`deleted_at`) - sem limite de tempo, diferente da
  /// edição.
  Future<void> delete(String id);

  Future<void> report(
    String commentId, {
    required String reportedBy,
    required String reason,
  });
}
