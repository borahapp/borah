import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../domain/event.dart';
import '../domain/event_attendance.dart';
import '../domain/event_details.dart';
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

  @override
  Future<List<Event>> listByGroup(String groupId) {
    return _guard(() async {
      final rows = await _datasource.listByGroup(groupId);
      return rows.map(_mapRow).toList();
    });
  }

  @override
  Future<EventDetails> getById(String eventId) {
    return _guard(() async {
      final eventRow = await _datasource.fetchEventById(eventId);
      final attendanceRows = await _datasource.fetchAttendances(eventId);

      final userIds = attendanceRows
          .map((a) => a['user_id'] as String)
          .toList();
      final profileRows = await _datasource.fetchProfilesByIds(userIds);
      final profilesById = {
        for (final profile in profileRows) profile['id'] as String: profile,
      };

      final attendances = attendanceRows.map((attendanceRow) {
        final userId = attendanceRow['user_id'] as String;
        final profile = profilesById[userId];
        return EventAttendance(
          id: attendanceRow['id'] as String,
          userId: userId,
          status: attendanceRow['status'] as String,
          fullName: profile?['full_name'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
        );
      }).toList();

      return EventDetails(event: _mapRow(eventRow), attendances: attendances);
    });
  }

  @override
  Future<void> confirmAttendance(String attendanceId) {
    return _guard(
      () => _datasource.updateAttendanceStatus(attendanceId, 'confirmed'),
    );
  }

  @override
  Future<void> declineAttendance(String attendanceId) {
    return _guard(
      () => _datasource.updateAttendanceStatus(attendanceId, 'declined'),
    );
  }

  @override
  Future<bool> isGroupAdmin({required String groupId, required String userId}) {
    return _guard(() async {
      final role = await _datasource.fetchOwnGroupRole(groupId, userId);
      return role == 'owner' || role == 'admin';
    });
  }

  @override
  Future<void> cancel(String eventId) {
    return _guard(() => _datasource.updateStatus(eventId, 'cancelled'));
  }

  @override
  Future<Event> reschedule({
    required String eventId,
    required DateTime scheduledAt,
  }) {
    return _guard(() async {
      final row = await _datasource.updateScheduledAt(eventId, scheduledAt);
      return _mapRow(row);
    });
  }

  @override
  Future<void> notifyReadyForReview() {
    return _guard(() => _datasource.notifyEventsReadyForReview());
  }

  Event _mapRow(Map<String, dynamic> row) {
    final restaurant = row['restaurants'] as Map<String, dynamic>?;
    // Mesmo padrão de `GroupRepositoryImpl._mapRow`/`Group.memberCount`
    // (Sprint 3) - `event_attendances` só existe na linha quando o
    // `select` pediu o embed filtrado (FASE B0); ausente no retorno de
    // `create_event()` (RPC sem embed), `confirmedCount` fica `0`.
    final attendanceRows = row['event_attendances'] as List?;
    final confirmedCount = attendanceRows != null && attendanceRows.isNotEmpty
        ? attendanceRows.first['count'] as int
        : 0;

    return Event(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      restaurantId: row['restaurant_id'] as String,
      organizerId: row['organizer_id'] as String,
      scheduledAt: DateTime.parse(row['scheduled_at'] as String),
      status: row['status'] as String,
      restaurantName: restaurant?['name'] as String?,
      restaurantCategory: restaurant?['category'] as String?,
      restaurantCity: restaurant?['city'] as String?,
      restaurantCoverImage: restaurant?['cover_image'] as String?,
      averageRating: (row['average_rating'] as num?)?.toDouble(),
      totalReviews: row['total_reviews'] as int? ?? 0,
      confirmedCount: confirmedCount,
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
