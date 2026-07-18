import 'dart:typed_data';

import '../../../core/models/paged_result.dart';
import 'review.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01/DV-02/DV-03) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class ReviewRepositoryException implements Exception {
  const ReviewRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio. Toda a construção de consultas PostgREST e do
/// Storage do bucket `review-photos` fica isolada em `data/` — o
/// controller nunca conhece esses detalhes (mesma decisão do DV-03).
abstract interface class ReviewRepository {
  Future<PagedResult<Review>> listByRestaurant(
    String restaurantId, {
    required int page,
    required int limit,
  });

  Future<Review> getById(String id);

  Future<Review> create({
    required String restaurantId,
    required String userId,
    required double rating,
    String? comment,
  });

  Future<Review> update(String id, {required double rating, String? comment});

  /// Exclusão lógica (DV-04) — define `deleted_at`, nunca remove a linha.
  Future<void> delete(String id);

  /// Bucket `review-photos` é público - o path é armazenado implicitamente
  /// na estrutura de pastas do bucket (`<reviewId>/<arquivo>`); não há
  /// tabela de fotos no modelo aprovado do DV-04 §9 (apenas `photos_count`).
  Future<Review> addPhoto(
    String id, {
    required Uint8List bytes,
    required String fileExtension,
  });

  Future<List<String>> listPhotoUrls(String reviewId);

  Future<void> like(String reviewId, String userId);

  Future<void> unlike(String reviewId, String userId);

  Future<bool> isLikedByUser(String reviewId, String userId);
}
