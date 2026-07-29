import 'dart:convert';
import 'dart:io';

/// Criação/remoção/consulta direta de restaurantes e avaliações via
/// PostgREST (`service_role`, ignora RLS) - QA-03, Rodada C.
///
/// Usado para preparar dados de precondição sem depender da tela de
/// Cadastro (que não é um dos cenários desta rodada) e para validar
/// persistência/gatilhos de banco (ex.: recálculo de `average_rating`)
/// de forma independente da renderização da tela.
///
/// **Importante:** `reviews.restaurant_id` e `reviews.user_id` usam
/// `ON DELETE RESTRICT` (ver `20260718230512_create_reviews.sql`) -
/// avaliações precisam ser removidas (hard delete, via [deleteReview])
/// antes de remover o restaurante ou o usuário correspondentes, mesmo
/// que a avaliação já tenha sido excluída logicamente (`deleted_at`)
/// pela própria aplicação.
class QaRestaurantHelper {
  QaRestaurantHelper({required this.supabaseUrl, required this.serviceRoleKey});

  final String supabaseUrl;
  final String serviceRoleKey;

  Future<String> createRestaurant({
    required String createdBy,
    required String name,
    String category = 'Bar',
    String? description,
    String? address,
    String? city,
    String? stateProvince,
  }) async {
    final id = await _post('restaurants', {
      'created_by': createdBy,
      'name': name,
      'category': category,
      'description': ?description,
      'address': ?address,
      'city': ?city,
      'state': ?stateProvince,
    });
    return id;
  }

  Future<String> createReview({
    required String restaurantId,
    required String userId,
    required double rating,
    String? comment,
  }) {
    return _post('reviews', {
      'restaurant_id': restaurantId,
      'user_id': userId,
      'rating': rating,
      'comment': ?comment,
    });
  }

  Future<Map<String, dynamic>?> fetchRestaurant(String id) =>
      _getSingle('restaurants', id);

  Future<Map<String, dynamic>?> fetchReview(String id) =>
      _getSingle('reviews', id);

  /// Localiza uma avaliação criada pelo fluxo real de UI (que não expõe
  /// o id ao chamador) - a constraint `UNIQUE(user_id, restaurant_id)`
  /// garante que existe no máximo uma linha por combinação.
  Future<Map<String, dynamic>?> fetchReviewByRestaurantAndUser({
    required String restaurantId,
    required String userId,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('$supabaseUrl/rest/v1/reviews').replace(
          queryParameters: {
            'restaurant_id': 'eq.$restaurantId',
            'user_id': 'eq.$userId',
            'select': '*',
          },
        ),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw StateError('Falha ao consultar reviews: $body');
      }
      final rows = jsonDecode(body) as List;
      return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  /// Hard delete - ver aviso na documentação da classe sobre a ordem de
  /// limpeza exigida pelas constraints `ON DELETE RESTRICT`.
  Future<void> deleteReview(String id) => _delete('reviews', id);

  Future<void> deleteRestaurant(String id) => _delete('restaurants', id);

  Future<String> _post(String table, Map<String, dynamic> body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse('$supabaseUrl/rest/v1/$table'),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Prefer', 'return=representation');
      // `request.write(String)` não garante codificação UTF-8 (usa o
      // `encoding` do IOSink, que pode divergir) - codificar os bytes
      // explicitamente evita corromper caracteres acentuados (ex.:
      // "São Paulo") no corpo da requisição.
      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode != 201) {
        throw StateError('Falha ao criar registro em $table: $responseBody');
      }
      final rows = jsonDecode(responseBody) as List;
      return (rows.first as Map<String, dynamic>)['id'] as String;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> _getSingle(String table, String id) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse(
          '$supabaseUrl/rest/v1/$table',
        ).replace(queryParameters: {'id': 'eq.$id', 'select': '*'}),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw StateError('Falha ao consultar $table: $body');
      }
      final rows = jsonDecode(body) as List;
      return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  Future<void> _delete(String table, String id) async {
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(
        Uri.parse(
          '$supabaseUrl/rest/v1/$table',
        ).replace(queryParameters: {'id': 'eq.$id'}),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');

      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw StateError(
          'Falha ao remover $table/$id (status ${response.statusCode}).',
        );
      }
    } finally {
      client.close();
    }
  }
}
