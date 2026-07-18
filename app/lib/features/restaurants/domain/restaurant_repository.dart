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

  Future<Restaurant> getById(String id);

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
}
