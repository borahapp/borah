import 'dart:typed_data';

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

      // `Future.wait` resolve as URLs assinadas das fotos em paralelo
      // (uma por avaliação com `photo_path`, RC-03 FASE A2) - nunca
      // sequencial, mesmo espírito de reuso/composição já usado em
      // `GroupRepositoryImpl.listMine()` (Sprint 3).
      return Future.wait(rows.map((row) => _mapRow(row, profilesById)));
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
      return await _mapRow(row, const {});
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
      return await _mapRow(row, const {});
    });
  }

  @override
  Future<EventReview> attachPhoto({
    required String reviewId,
    required Uint8List bytes,
    required String fileExtension,
    String? previousPath,
  }) {
    return _guard(() async {
      final path = await _datasource.uploadPhoto(
        reviewId,
        bytes,
        fileExtension,
        previousPath: previousPath,
      );
      final row = await _datasource.updatePhotoPath(reviewId, path);
      return _mapRow(row, const {});
    });
  }

  @override
  Future<EventReview> removePhoto({
    required String reviewId,
    required String photoPath,
  }) {
    return _guard(() async {
      await _datasource.deletePhoto(photoPath);
      final row = await _datasource.updatePhotoPath(reviewId, null);
      return _mapRow(row, const {});
    });
  }

  @override
  Future<String> getPhotoUrl(String photoPath) {
    return _guard(() => _datasource.getPhotoUrl(photoPath));
  }

  Future<EventReview> _mapRow(
    Map<String, dynamic> row,
    Map<String, dynamic> profilesById,
  ) async {
    final userId = row['user_id'] as String;
    final profile = profilesById[userId];
    final photoPath = row['photo_path'] as String?;
    final photoUrl = photoPath == null
        ? null
        : await _datasource.getPhotoUrl(photoPath);
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
      photoPath: photoPath,
      photoUrl: photoUrl,
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
