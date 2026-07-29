import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_preference_repository_impl.dart';
import '../domain/notification_preference_repository.dart';
import '../presentation/states/notification_preferences_status.dart';

class NotificationPreferencesController
    extends Notifier<NotificationPreferencesStatus> {
  @override
  NotificationPreferencesStatus build() =>
      const NotificationPreferencesInitial();

  NotificationPreferenceRepository get _repository =>
      ref.read(notificationPreferenceRepositoryProvider);

  Future<void> load(String userId) async {
    state = const NotificationPreferencesLoading();
    try {
      final enabled = await _repository.isInAppEnabled(userId);
      state = NotificationPreferencesLoaded(enabled);
    } on NotificationPreferenceRepositoryException catch (e) {
      state = NotificationPreferencesError(e.message);
    } catch (_) {
      state = const NotificationPreferencesError(
        'Não foi possível carregar as preferências.',
      );
    }
  }

  Future<void> toggle(String userId) async {
    final current = state;
    if (current is! NotificationPreferencesLoaded) return;
    final newValue = !current.inAppEnabled;
    try {
      await _repository.setInAppEnabled(userId, newValue);
      state = NotificationPreferencesLoaded(newValue);
    } on NotificationPreferenceRepositoryException catch (e) {
      state = NotificationPreferencesError(e.message);
    } catch (_) {
      state = const NotificationPreferencesError(
        'Não foi possível atualizar a preferência.',
      );
    }
  }
}

final notificationPreferencesControllerProvider =
    NotifierProvider<
      NotificationPreferencesController,
      NotificationPreferencesStatus
    >(NotificationPreferencesController.new);
