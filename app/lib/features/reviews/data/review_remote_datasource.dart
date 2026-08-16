import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/app_storage.dart';
import '../../../core/storage/storage_upload_config.dart';

/// Encapsula toda a construção de consultas PostgREST (listagem paginada,
/// curtidas) e o Storage do bucket `review-photos` (público) - DV-04.
/// Nenhuma camada acima desta conhece esses detalhes (mesma decisão do DV-03).
class ReviewRemoteDatasource {
  ReviewRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'reviews';
  static const _likesTable = 'review_likes';
  static const _profilesTable = 'profiles';
  static const _bucket = 'review-photos';

  /// `restaurants(...)` é um embed válido (`reviews.restaurant_id` tem FK
  /// direta para `restaurants.id`) - diferente de `profiles`
  /// (`reviews.user_id` referencia `auth.users`, sem FK direta), que por
  /// isso é sempre resolvido à parte via [fetchProfilesByIds] (mesma
  /// limitação/padrão já documentado no Feed e em `event_reviews`).
  ///
  /// BETA-RELEASE-03: embed NÃO usa `!inner` (join opcional, não
  /// obrigatório) - `!inner` fazia a linha de `reviews` inteira
  /// desaparecer do resultado sempre que o embed de `restaurants` não
  /// resolvia (raiz da regressão "Nenhuma avaliação ainda." reportada em
  /// BETA-RELEASE-02, mecanismo exato não confirmado, mas correlação de
  /// código com o commit que introduziu `!inner` era a única mudança
  /// entre "lista funcionava" e "lista vazia"). Com embed opcional, a
  /// review nunca é descartada por causa do restaurante; `_mapRow` em
  /// `review_repository_impl.dart` trata `row['restaurants']` como
  /// nulável.
  static const _reviewsSelect = '*, restaurants(id, name, cover_image)';

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
        .select(_reviewsSelect)
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
        .select(_reviewsSelect)
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> fetchById(String id) {
    return _client
        .from(_table)
        .select(_reviewsSelect)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .single();
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) {
    return _client.from(_table).insert(data).select(_reviewsSelect).single();
  }

  Future<Map<String, dynamic>> updatePatch(
    String id,
    Map<String, dynamic> patch,
  ) {
    return _client
        .from(_table)
        .update(patch)
        .eq('id', id)
        .select(_reviewsSelect)
        .single();
  }

  /// Perfis dos autores, buscados à parte - ver comentário de
  /// [_reviewsSelect]. Duplicado por feature (mesma decisão já tomada em
  /// `FeedRemoteDatasource`/`FollowerRemoteDatasource`/
  /// `EventReviewRemoteDatasource`).
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_profilesTable)
        .select('id, full_name, avatar_url')
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> softDelete(String id) {
    return _client
        .from(_table)
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  /// Pasta `<reviewId>/` no bucket público `review-photos`, via
  /// `AppStorage` (RC-04B) - 2B.3: antes chamava `_client.storage` direto,
  /// sem validar tamanho/MIME/extensão nem a assinatura real dos bytes
  /// (`matchesImageSignature`); agora usa o mesmo caminho seguro já
  /// conectado por `EventReviewRemoteDatasource.uploadPhoto`. Nome do
  /// arquivo é sempre gerado (nunca o do usuário), permitindo múltiplas
  /// fotos por avaliação.
  Future<String> uploadPhoto(
    String reviewId,
    Uint8List bytes,
    String fileExtension,
  ) {
    return AppStorage.upload(
      bucket: _bucket,
      folder: reviewId,
      bytes: bytes,
      originalFileName: 'photo.$fileExtension',
      contentType: _mimeTypeFor(fileExtension),
      config: StorageUploadConfig.reviewPhoto,
    );
  }

  /// `ImagePickerService` só devolve bytes+extensão, nunca o MIME -
  /// `AppStorage.upload` exige `contentType` explícito (mesmo mapeamento
  /// já usado em `EventReviewRemoteDatasource._mimeTypeFor`, duplicado
  /// aqui por decisão consciente - cada datasource mantém sua própria
  /// cópia, mesmo padrão de `fetchProfilesByIds` no projeto).
  String _mimeTypeFor(String extension) => switch (extension.toLowerCase()) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

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
