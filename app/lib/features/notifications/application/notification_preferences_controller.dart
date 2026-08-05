import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_preference_repository_impl.dart';
import '../domain/notification_preference_repository.dart';
import '../presentation/states/notification_preferences_status.dart';

/// Categorias expostas na UI (RC-03 Sprint 0 - F48). Valores idênticos aos
/// aceitos por `notification_preferences_category_check` no banco.
abstract class NotificationPreferenceCategory {
  static const social = 'social';
  static const groups = 'groups';
}

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
      final results = await Future.wait([
        _repository.isInAppEnabled(
          userId,
          NotificationPreferenceCategory.social,
        ),
        _repository.isInAppEnabled(
          userId,
          NotificationPreferenceCategory.groups,
        ),
      ]);
      state = NotificationPreferencesLoaded(
        socialEnabled: results[0],
        groupsEnabled: results[1],
      );
    } on NotificationPreferenceRepositoryException catch (e) {
      state = NotificationPreferencesError(e.message);
    } catch (_) {
      state = const NotificationPreferencesError(
        'Não foi possível carregar as preferências.',
      );
    }
  }

  Future<void> toggle(String userId, String category) async {
    final current = state;
    if (current is! NotificationPreferencesLoaded) return;

    final newValue = switch (category) {
      NotificationPreferenceCategory.social => !current.socialEnabled,
      NotificationPreferenceCategory.groups => !current.groupsEnabled,
      _ => throw ArgumentError('Categoria desconhecida: $category'),
    };

    try {
      await _repository.setInAppEnabled(userId, category, newValue);
      state = switch (category) {
        NotificationPreferenceCategory.social => current.copyWith(
          socialEnabled: newValue,
        ),
        NotificationPreferenceCategory.groups => current.copyWith(
          groupsEnabled: newValue,
        ),
        _ => current,
      };
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
