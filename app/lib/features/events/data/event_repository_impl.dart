import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../domain/event.dart';
import '../domain/event_repository.dart';
import 'event_remote_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._datasource);

  final EventRemoteDatasource _datasource;

  @override
  Future<Event> create({
    required String groupId,
    required String restaurantId,
    required DateTime scheduledAt,
  }) {
    return _guard(() async {
      final row = await _datasource.createEvent(
        groupId: groupId,
        restaurantId: restaurantId,
        scheduledAt: scheduledAt,
      );
      return _mapRow(row);
    });
  }

  Event _mapRow(Map<String, dynamic> row) {
    return Event(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      restaurantId: row['restaurant_id'] as String,
      scheduledAt: DateTime.parse(row['scheduled_at'] as String),
      status: row['status'] as String,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw EventRepositoryException(e.message);
    }
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EventRepositoryImpl(EventRemoteDatasource(client));
});
