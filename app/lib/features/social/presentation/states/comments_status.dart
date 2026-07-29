import '../../../../core/models/paged_result.dart';
import '../../domain/comment.dart';

/// Estado da listagem/gestão de comentários de uma avaliação (DV-07),
/// sealed class. Prefixo `Comments*` para evitar colisão com estados de
/// outros módulos (mesma lição do DV-01 em diante).
sealed class CommentsStatus {
  const CommentsStatus();
}

final class CommentsInitial extends CommentsStatus {
  const CommentsInitial();
}

final class CommentsLoading extends CommentsStatus {
  const CommentsLoading();
}

final class CommentsLoaded extends CommentsStatus {
  const CommentsLoaded(this.result);

  final PagedResult<Comment> result;
}

final class CommentsEmpty extends CommentsStatus {
  const CommentsEmpty();
}

/// Publicando/editando/excluindo/denunciando um comentário - mantém a
/// lista anterior visível (DV-07 §10 "Publishing").
final class CommentsPublishing extends CommentsStatus {
  const CommentsPublishing(this.result);

  final PagedResult<Comment> result;
}

final class CommentsError extends CommentsStatus {
  const CommentsError(this.message);

  final String message;
}
