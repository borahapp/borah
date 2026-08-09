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

  /// Avaliações de um usuário específico (DV-07 - aba "avaliações" do
  /// Perfil público). Mesma entidade `Review`, apenas outro filtro.
  Future<PagedResult<Review>> listByUser(
    String userId, {
    required int page,
    required int limit,
  });

  Future<Review> getById(String id);

  /// RC-03 F16 - os 5 critérios seguem exatamente o mesmo papel de
  /// `event_reviews` (`20260801100000_create_event_reviews.sql`):
  /// `rating` é a nota geral, um input independente do usuário (mesmo
  /// papel de `overall_score`), não uma média calculada dos outros 4 —
  /// os 4 novos (ambiente/atendimento/comida/custo-benefício) são
  /// critérios objetivos adicionais, também inputs independentes.
  Future<Review> create({
    required String restaurantId,
    required String userId,
    required double rating,
    required double ambienceScore,
    required double serviceScore,
    required double foodScore,
    required double costBenefitScore,
    String? comment,
  });

  Future<Review> update(
    String id, {
    required double rating,
    required double ambienceScore,
    required double serviceScore,
    required double foodScore,
    required double costBenefitScore,
    String? comment,
  });

  /// Exclusão lógica (DV-04) — define `deleted_at`, nunca remove a linha.
  Future<void> delete(String id);

  /// Oculta (exclusão lógica) qualquer avaliação, independente do autor
  /// (DV-08 - Moderação de Avaliações, exceção documentada ao AR-13,
  /// autorizada por RLS baseada em papel).
  Future<void> hideAsAdmin(String id);

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

  /// RC-03 F14 - galeria de fotos do restaurante: agrega as fotos já
  /// anexadas pelas avaliações individuais (`listPhotoUrls` por review),
  /// sem tabela nova - reaproveita o bucket `review-photos` já existente
  /// (`RC03_FEATURE_GAP.md §5.3`). Para no primeiro [limit] fotos
  /// encontradas, não busca fotos de todas as avaliações do restaurante
  /// incondicionalmente.
  Future<List<String>> listRestaurantPhotos(
    String restaurantId, {
    int limit = 12,
  });
}
