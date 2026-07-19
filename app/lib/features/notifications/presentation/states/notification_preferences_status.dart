/// Estado da tela de Preferências (DV-09), sealed class. Só a categoria
/// 'social' é exposta (decisão 5/7 do DV-09).
sealed class NotificationPreferencesStatus {
  const NotificationPreferencesStatus();
}

final class NotificationPreferencesInitial
    extends NotificationPreferencesStatus {
  const NotificationPreferencesInitial();
}

final class NotificationPreferencesLoading
    extends NotificationPreferencesStatus {
  const NotificationPreferencesLoading();
}

final class NotificationPreferencesLoaded
    extends NotificationPreferencesStatus {
  const NotificationPreferencesLoaded(this.inAppEnabled);

  final bool inAppEnabled;
}

final class NotificationPreferencesError extends NotificationPreferencesStatus {
  const NotificationPreferencesError(this.message);

  final String message;
}
