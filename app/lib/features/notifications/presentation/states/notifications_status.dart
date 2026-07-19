import '../../../../core/models/paged_result.dart';
import '../../domain/app_notification.dart';

/// Estado da Central de Notificações (DV-09), sealed class. Prefixo
/// `Notifications*` para evitar colisão com estados de outros módulos.
sealed class NotificationsStatus {
  const NotificationsStatus();
}

final class NotificationsInitial extends NotificationsStatus {
  const NotificationsInitial();
}

final class NotificationsLoading extends NotificationsStatus {
  const NotificationsLoading();
}

final class NotificationsLoaded extends NotificationsStatus {
  const NotificationsLoaded(this.result);

  final PagedResult<AppNotification> result;
}

final class NotificationsEmpty extends NotificationsStatus {
  const NotificationsEmpty();
}

final class NotificationsError extends NotificationsStatus {
  const NotificationsError(this.message);

  final String message;
}
