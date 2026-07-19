import '../../../../core/models/paged_result.dart';
import '../../../social/domain/comment_report.dart';

/// Estado da fila de denúncias (DV-08 - Moderação), sealed class.
sealed class ModerationStatus {
  const ModerationStatus();
}

final class ModerationInitial extends ModerationStatus {
  const ModerationInitial();
}

final class ModerationLoading extends ModerationStatus {
  const ModerationLoading();
}

final class ModerationLoaded extends ModerationStatus {
  const ModerationLoaded(this.result);

  final PagedResult<CommentReport> result;
}

final class ModerationEmpty extends ModerationStatus {
  const ModerationEmpty();
}

final class ModerationProcessing extends ModerationStatus {
  const ModerationProcessing(this.result);

  final PagedResult<CommentReport> result;
}

final class ModerationError extends ModerationStatus {
  const ModerationError(this.message);

  final String message;
}
