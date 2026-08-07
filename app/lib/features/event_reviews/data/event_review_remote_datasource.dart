import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/app_storage.dart';
import '../../../core/storage/storage_upload_config.dart';

/// Encapsula todo acesso a `event_reviews` via PostgREST (BLOCO 4).
///
/// Sem RPC - a RLS (`event_reviews_insert_own`/`can_review_event`,
/// migration `20260801100000_create_event_reviews.sql`) já garante
/// tudo que uma função `SECURITY DEFINER` garantiria aqui: um único
/// INSERT, sem fan-out para outras tabelas (diferente de
/// `create_event()`/`create_group()`, que precisam de RPC porque
/// escrevem em duas tabelas atomicamente).
class EventReviewRemoteDatasource {
  EventReviewRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'event_reviews';
  static const _profilesTable = 'profiles';
  static const _bucket = 'event-review-photos';

  static const _columns =
      'id,event_id,user_id,food_score,service_score,ambience_score,'
      'cost_benefit_score,overall_score,comment,photo_path';

  /// Sem embed com `profiles` - mesma limitação de
  /// `EventRemoteDatasource.fetchAttendances` (sem FK direta).
  Future<List<Map<String, dynamic>>> listByEvent(String eventId) async {
    final rows = await _client
        .from(_table)
        .select(_columns)
        .eq('event_id', eventId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Mesmo método/assinatura de `EventRemoteDatasource.fetchProfilesByIds`
  /// - duplicado aqui em vez de compartilhado, mesma decisão já tomada
  /// para todo par datasource/`profiles` do projeto.
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_profilesTable)
        .select()
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> submit({
    required String eventId,
    required String userId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  }) {
    return _client
        .from(_table)
        .insert({
          'event_id': eventId,
          'user_id': userId,
          'food_score': foodScore,
          'service_score': serviceScore,
          'ambience_score': ambienceScore,
          'cost_benefit_score': costBenefitScore,
          'overall_score': overallScore,
          'comment': comment,
        })
        .select(_columns)
        .single();
  }

  Future<Map<String, dynamic>> update({
    required String reviewId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  }) {
    return _client
        .from(_table)
        .update({
          'food_score': foodScore,
          'service_score': serviceScore,
          'ambience_score': ambienceScore,
          'cost_benefit_score': costBenefitScore,
          'overall_score': overallScore,
          'comment': comment,
        })
        .eq('id', reviewId)
        .select(_columns)
        .single();
  }

  /// Pasta `<reviewId>/` no bucket privado `event-review-photos`
  /// (RC-03 FASE A2) - mesma técnica de pasta-por-id já usada por
  /// `review-photos`, via `AppStorage` (RC-04B), primeira feature a
  /// efetivamente conectar essa infraestrutura a uma tela. Com
  /// [previousPath], troca com limpeza best-effort do arquivo antigo
  /// (`AppStorage.replace`); sem, é o primeiro upload.
  Future<String> uploadPhoto(
    String reviewId,
    Uint8List bytes,
    String fileExtension, {
    String? previousPath,
  }) {
    final contentType = _mimeTypeFor(fileExtension);
    if (previousPath == null) {
      return AppStorage.upload(
        bucket: _bucket,
        folder: reviewId,
        bytes: bytes,
        originalFileName: 'photo.$fileExtension',
        contentType: contentType,
        config: StorageUploadConfig.eventReviewPhoto,
      );
    }
    return AppStorage.replace(
      bucket: _bucket,
      folder: reviewId,
      bytes: bytes,
      originalFileName: 'photo.$fileExtension',
      contentType: contentType,
      config: StorageUploadConfig.eventReviewPhoto,
      previousPath: previousPath,
    );
  }

  Future<void> deletePhoto(String photoPath) {
    return AppStorage.delete(bucket: _bucket, path: photoPath);
  }

  /// Bucket privado - URL assinada, nunca pública (`AppStorage.
  /// getSignedUrl`, mesma técnica já usada para `avatars`).
  Future<String> getPhotoUrl(String photoPath) {
    return AppStorage.getSignedUrl(bucket: _bucket, path: photoPath);
  }

  Future<Map<String, dynamic>> updatePhotoPath(
    String reviewId,
    String? photoPath,
  ) {
    return _client
        .from(_table)
        .update({'photo_path': photoPath})
        .eq('id', reviewId)
        .select(_columns)
        .single();
  }

  /// `ImagePickerService` (compartilhado) só devolve bytes+extensão,
  /// nunca o MIME - `AppStorage.upload`/`.replace` exigem `contentType`
  /// explícito para validar contra `StorageUploadConfig.
  /// allowedMimeTypes`. Mapeamento local (não extraído para um helper
  /// compartilhado): esta é a primeira feature a conectar `AppStorage`
  /// a uma tela real - extrair um helper comum fica para quando
  /// `reviews`/`restaurants`/`avatars` também migrarem para cá.
  String _mimeTypeFor(String extension) => switch (extension.toLowerCase()) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
