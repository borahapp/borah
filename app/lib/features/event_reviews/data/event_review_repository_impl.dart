import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../domain/event_review.dart';
import '../domain/event_review_repository.dart';
import 'event_review_remote_datasource.dart';

class EventReviewRepositoryImpl implements EventReviewRepository {
  EventReviewRepositoryImpl(this._datasource);

  final EventReviewRemoteDatasource _datasource;

  @override
  Future<List<EventReview>> listByEvent(String eventId) {
    return _guard(() async {
      final rows = await _datasource.listByEvent(eventId);

      final userIds = rows.map((r) => r['user_id'] as String).toList();
      final profileRows = await _datasource.fetchProfilesByIds(userIds);
      final profilesById = {
        for (final profile in profileRows) profile['id'] as String: profile,
      };

      return rows.map((row) => _mapRow(row, profilesById)).toList();
    });
  }

  @override
  Future<EventReview> submit({
    required String eventId,
    required String userId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  }) {
    return _guard(() async {
      final row = await _datasource.submit(
        eventId: eventId,
        userId: userId,
        foodScore: foodScore,
        serviceScore: serviceScore,
        ambienceScore: ambienceScore,
        costBenefitScore: costBenefitScore,
        overallScore: overallScore,
        comment: comment,
      );
      return _mapRow(row, const {});
    });
  }

  @override
  Future<EventReview> update({
    required String reviewId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  }) {
    return _guard(() async {
      final row = await _datasource.update(
        reviewId: reviewId,
        foodScore: foodScore,
        serviceScore: serviceScore,
        ambienceScore: ambienceScore,
        costBenefitScore: costBenefitScore,
        overallScore: overallScore,
        comment: comment,
      );
      return _mapRow(row, const {});
    });
  }

  EventReview _mapRow(
    Map<String, dynamic> row,
    Map<String, dynamic> profilesById,
  ) {
    final userId = row['user_id'] as String;
    final profile = profilesById[userId];
    return EventReview(
      id: row['id'] as String,
      eventId: row['event_id'] as String,
      userId: userId,
      foodScore: (row['food_score'] as num).toDouble(),
      serviceScore: (row['service_score'] as num).toDouble(),
      ambienceScore: (row['ambience_score'] as num).toDouble(),
      costBenefitScore: (row['cost_benefit_score'] as num).toDouble(),
      overallScore: (row['overall_score'] as num).toDouble(),
      comment: row['comment'] as String?,
      fullName: profile?['full_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw EventReviewRepositoryException(e.message);
    }
  }
}

final eventReviewRepositoryProvider = Provider<EventReviewRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EventReviewRepositoryImpl(EventReviewRemoteDatasource(client));
});
