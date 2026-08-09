import 'dart:typed_data';

import '../../../core/models/paged_result.dart';
import 'restaurant.dart';
import 'restaurant_search_filters.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01/DV-02) —
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class RestaurantRepositoryException implements Exception {
  const RestaurantRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio. Toda a lógica de construção de consulta (busca,
/// filtros, paginação) fica encapsulada na implementação em `data/` —
/// o controller só manda um `RestaurantSearchFilters` e recebe um
/// `PagedResult<Restaurant>`, sem conhecer PostgREST.
abstract interface class RestaurantRepository {
  Future<PagedResult<Restaurant>> search(RestaurantSearchFilters filters);

  /// Consulta ordenada por relevância (média desc, total de avaliações
  /// desc, mais recente desc, nome asc - DV-05 §6) - usada pelo
  /// `RankingRepository`, que delega para este método em vez de duplicar
  /// a construção de consulta em um datasource próprio.
  Future<PagedResult<Restaurant>> listRanked({
    String? city,
    String? category,
    required int page,
    required int limit,
  });

  Future<Restaurant> getById(String id);

  /// Lista TODOS os restaurantes, incluindo arquivados/inativos (DV-08 -
  /// Gestão de Restaurantes) - diferente de `search`, que só mostra
  /// restaurantes ativos ao público.
  Future<PagedResult<Restaurant>> listAllForAdmin({
    String? query,
    required int page,
    required int limit,
  });

  /// Edita/arquiva/reativa qualquer restaurante, independente do
  /// `created_by` (DV-08 - exceção documentada ao AR-13, autorizada por
  /// RLS baseada em papel, não pelo dono da linha).
  Future<Restaurant> updateAsAdmin(
    String id, {
    String? name,
    String? category,
    String? description,
    String? address,
    String? city,
    String? stateProvince,
    String? status,
  });

  Future<Restaurant> create({
    required String createdBy,
    required String name,
    required String category,
    String? description,
    String? address,
    String? city,
    String? stateProvince,
    double? latitude,
    double? longitude,
  });

  /// Bucket `restaurants` é público (AR-08) — o path é armazenado em
  /// `cover_image`; a resolução para URL pública fica em `data/`.
  Future<Restaurant> updateCoverImage(
    String restaurantId, {
    required Uint8List bytes,
    required String fileExtension,
  });

  /// RC-03 F13 - restaurantes favoritados por pelo menos 1 membro do
  /// grupo, ainda não visitados pelo grupo (nenhum rolê para eles ainda).
  /// Via RPC (`suggest_group_restaurants`) porque `favorites` só é
  /// legível pelo próprio dono - o cliente não pode agregar favoritos de
  /// outros membros diretamente.
  Future<List<Restaurant>> suggestForGroup(String groupId);
}
