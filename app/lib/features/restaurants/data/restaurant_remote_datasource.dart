import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST (busca, filtros,
/// paginação) e o Storage do bucket `restaurants` (público) - DV-03 §7/§13.
/// Nenhuma camada acima desta conhece esses detalhes (decisão do DV-03).
class RestaurantRemoteDatasource {
  RestaurantRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'restaurants';
  static const _bucket = 'restaurants';

  /// Busca `limit + 1` registros para permitir detectar se há próxima
  /// página sem depender de uma contagem exata (ver core/models/paged_result.dart).
  Future<List<Map<String, dynamic>>> search({
    String? query,
    String? city,
    String? category,
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    var builder = _client
        .from(_table)
        .select()
        .eq('status', 'active')
        .isFilter('deleted_at', null);

    if (query != null && query.isNotEmpty) {
      builder = builder.ilike('name', '%$query%');
    }
    if (city != null && city.isNotEmpty) {
      builder = builder.eq('city', city);
    }
    if (category != null && category.isNotEmpty) {
      builder = builder.eq('category', category);
    }

    final rows = await builder.range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Ranking (DV-05 §6): média desc, total de avaliações desc, mais
  /// recente desc, nome asc como desempate final. Sem `ranking_position`
  /// armazenado - a posição é derivada de `page`/`limit`/índice pela
  /// camada de aplicação (DV-05 não tem tabela própria).
  Future<List<Map<String, dynamic>>> listRanked({
    String? city,
    String? category,
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    var builder = _client
        .from(_table)
        .select()
        .eq('status', 'active')
        .isFilter('deleted_at', null)
        .not('average_rating', 'is', null);

    if (city != null && city.isNotEmpty) {
      builder = builder.eq('city', city);
    }
    if (category != null && category.isNotEmpty) {
      builder = builder.eq('category', category);
    }

    final rows = await builder
        .order('average_rating', ascending: false)
        .order('total_reviews', ascending: false)
        .order('updated_at', ascending: false)
        .order('name', ascending: true)
        .range(from, to);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> fetchById(String id) {
    return _client.from(_table).select().eq('id', id).single();
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

  Future<String> uploadCoverImage(
    String restaurantId,
    Uint8List bytes,
    String fileExtension,
  ) async {
    final path = '$restaurantId/cover.$fileExtension';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  /// Bucket público - URL direta, sem necessidade de assinatura (diferente
  /// do bucket `avatars`, privado, no DV-02).
  String getPublicCoverImageUrl(String path) {
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
