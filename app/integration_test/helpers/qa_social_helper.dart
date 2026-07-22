import 'dart:convert';
import 'dart:io';

/// Criação/remoção/consulta direta de favoritos e relações de seguidor
/// via PostgREST (`service_role`, ignora RLS) - QA-03, Rodada D.
///
/// Usado para preparar dados de precondição (ex.: relação de seguidor
/// exigida pelo Feed, DV-07) sem depender de telas fora do escopo desta
/// rodada (seguir usuário não é um dos cenários), e para validar
/// persistência/constraints de forma independente da renderização.
///
/// **Nota sobre limpeza:** diferente de `reviews` (Rodada C,
/// `ON DELETE RESTRICT`), tanto `favorites` quanto `followers` usam
/// `ON DELETE CASCADE` em todas as FKs (`20260719140000_create_favorites.sql`,
/// `20260719150000_create_followers.sql`) - remover o restaurante ou os
/// usuários envolvidos já remove as linhas correspondentes
/// automaticamente. Os métodos de remoção aqui existem apenas para os
/// cenários que precisam observar a remoção acontecer durante o teste
/// (não para a limpeza final de `tearDown`).
class QaSocialHelper {
  QaSocialHelper({required this.supabaseUrl, required this.serviceRoleKey});

  final String supabaseUrl;
  final String serviceRoleKey;

  Future<void> addFavorite(String userId, String restaurantId) {
    return _post('favorites', {
      'user_id': userId,
      'restaurant_id': restaurantId,
    });
  }

  Future<Map<String, dynamic>?> fetchFavorite(
    String userId,
    String restaurantId,
  ) {
    return _getSingleWhere('favorites', {
      'user_id': 'eq.$userId',
      'restaurant_id': 'eq.$restaurantId',
    });
  }

  Future<void> follow(String followerId, String followingId) {
    return _post('followers', {
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> _post(String table, Map<String, dynamic> body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse('$supabaseUrl/rest/v1/$table'),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Prefer', 'return=representation');
      // Mesmo cuidado de encoding UTF-8 da Rodada C
      // (`qa_restaurant_helper.dart`) - `write(String)` não garante
      // UTF-8, ainda que nenhum dado desta classe contenha acentos hoje.
      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode != 201) {
        throw StateError('Falha ao criar registro em $table: $responseBody');
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> _getSingleWhere(
    String table,
    Map<String, String> filters,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse(
          '$supabaseUrl/rest/v1/$table',
        ).replace(queryParameters: {...filters, 'select': '*'}),
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
}
