import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../domain/notification_preference_repository.dart';
import 'notification_preference_remote_datasource.dart';

class NotificationPreferenceRepositoryImpl
    implements NotificationPreferenceRepository {
  NotificationPreferenceRepositoryImpl(this._datasource);

  final NotificationPreferenceRemoteDatasource _datasource;

  @override
  Future<bool> isInAppEnabled(String userId) {
    return _guard(() => _datasource.fetchInAppEnabled(userId));
  }

  @override
  Future<void> setInAppEnabled(String userId, bool enabled) {
    return _guard(() => _datasource.upsertInAppEnabled(userId, enabled));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw NotificationPreferenceRepositoryException(e.message);
    }
  }
}

final notificationPreferenceRepositoryProvider =
    Provider<NotificationPreferenceRepository>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return NotificationPreferenceRepositoryImpl(
        NotificationPreferenceRemoteDatasource(client),
      );
    });
