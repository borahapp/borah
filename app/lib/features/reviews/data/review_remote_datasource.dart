import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST (listagem paginada,
/// curtidas) e o Storage do bucket `review-photos` (público) - DV-04.
/// Nenhuma camada acima desta conhece esses detalhes (mesma decisão do DV-03).
class ReviewRemoteDatasource {
  ReviewRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'reviews';
  static const _likesTable = 'review_likes';
  static const _bucket = 'review-photos';

  /// Busca `limit + 1` registros para permitir detectar se há próxima
  /// página sem depender de uma contagem exata (core/models/paged_result.dart).
  Future<List<Map<String, dynamic>>> listByRestaurant(
    String restaurantId, {
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    final rows = await _client
        .from(_table)
        .select()
        .eq('restaurant_id', restaurantId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> listByUser(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> fetchById(String id) {
    return _client
        .from(_table)
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .single();
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) {
    return _client.from(_table).insert(data).select().single();
  }

  Future<Map<String, dynamic>> updatePatch(
    String id,
    Map<String, dynamic> patch,
  ) {
    return _client.from(_table).update(patch).eq('id', id).select().single();
  }

  Future<void> softDelete(String id) {
    return _client
        .from(_table)
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  /// Nome do arquivo inclui um timestamp para permitir múltiplas fotos por
  /// avaliação (diferente do `cover.$ext` fixo do DV-03, que substitui uma
  /// única imagem).
  Future<String> uploadPhoto(
    String reviewId,
    Uint8List bytes,
    String fileExtension,
  ) async {
    final path =
        '$reviewId/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from(_bucket).uploadBinary(path, bytes);
    return path;
  }

  /// Não há tabela de fotos no modelo aprovado do DV-04 (apenas
  /// `photos_count`) - a lista de fotos é resolvida listando os objetos da
  /// pasta `<reviewId>/` no bucket público, sem depender de uma tabela extra.
  Future<List<String>> listPhotoUrls(String reviewId) async {
    final objects = await _client.storage.from(_bucket).list(path: reviewId);
    return objects
        .map(
          (o) =>
              _client.storage.from(_bucket).getPublicUrl('$reviewId/${o.name}'),
        )
        .toList();
  }

  Future<void> like(String reviewId, String userId) {
    return _client.from(_likesTable).insert({
      'review_id': reviewId,
      'user_id': userId,
    });
  }

  Future<void> unlike(String reviewId, String userId) {
    return _client
        .from(_likesTable)
        .delete()
        .eq('review_id', reviewId)
        .eq('user_id', userId);
  }

  Future<bool> isLikedByUser(String reviewId, String userId) async {
    final rows = await _client
        .from(_likesTable)
        .select('review_id')
        .eq('review_id', reviewId)
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows).isNotEmpty;
  }
}
