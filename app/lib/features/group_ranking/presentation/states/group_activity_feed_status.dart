import '../../../../core/models/paged_result.dart';
import '../../../notifications/domain/app_notification.dart';

/// Estado da aba "Atividade" de `GroupHubPage` (RC-03 F25), sealed class -
/// mesmo formato de `NotificationsStatus`, prefixo próprio para não
/// colidir.
sealed class GroupActivityFeedStatus {
  const GroupActivityFeedStatus();
}

final class GroupActivityFeedInitial extends GroupActivityFeedStatus {
  const GroupActivityFeedInitial();
}

final class GroupActivityFeedLoading extends GroupActivityFeedStatus {
  const GroupActivityFeedLoading();
}

final class GroupActivityFeedLoaded extends GroupActivityFeedStatus {
  const GroupActivityFeedLoaded(this.result);

  final PagedResult<AppNotification> result;
}

final class GroupActivityFeedEmpty extends GroupActivityFeedStatus {
  const GroupActivityFeedEmpty();
}

final class GroupActivityFeedError extends GroupActivityFeedStatus {
  const GroupActivityFeedError(this.message);

  final String message;
}
