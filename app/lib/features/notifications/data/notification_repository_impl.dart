import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';
import 'notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._datasource);

  final NotificationRemoteDatasource _datasource;

  @override
  Future<PagedResult<AppNotification>> listForUser(
    String userId, {
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listForUser(
        userId,
        page: page,
        limit: limit,
      );

      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      return PagedResult<AppNotification>(
        items: pageRows.map(_mapRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  @override
  Future<void> markAsRead(String id) {
    return _guard(() => _datasource.markAsRead(id));
  }

  @override
  Future<void> markAllAsRead(String userId) {
    return _guard(() => _datasource.markAllAsRead(userId));
  }

  AppNotification _mapRow(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      type: row['type'] as String,
      title: row['title'] as String,
      message: row['message'] as String,
      payload: row['payload'] as Map<String, dynamic>?,
      isRead: row['is_read'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
      readAt: row['read_at'] != null
          ? DateTime.parse(row['read_at'] as String)
          : null,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw NotificationRepositoryException(e.message);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationRepositoryImpl(NotificationRemoteDatasource(client));
});
