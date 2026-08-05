/// Estado da tela de Preferências (DV-09), sealed class. RC-03 Sprint 0
/// (F48) estendeu de 1 para 2 categorias expostas na UI ('social' e
/// 'groups') - as demais categorias do CHECK constraint continuam sem UI.
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
  const NotificationPreferencesLoaded({
    required this.socialEnabled,
    required this.groupsEnabled,
  });

  final bool socialEnabled;
  final bool groupsEnabled;

  NotificationPreferencesLoaded copyWith({
    bool? socialEnabled,
    bool? groupsEnabled,
  }) {
    return NotificationPreferencesLoaded(
      socialEnabled: socialEnabled ?? this.socialEnabled,
      groupsEnabled: groupsEnabled ?? this.groupsEnabled,
    );
  }
}

final class NotificationPreferencesError extends NotificationPreferencesStatus {
  const NotificationPreferencesError(this.message);

  final String message;
}
