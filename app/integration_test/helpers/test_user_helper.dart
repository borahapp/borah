import 'dart:convert';
import 'dart:io';

/// Criação/remoção/consulta de usuários de teste via Supabase Admin API
/// e PostgREST - criado como scaffolding na Rodada A (QA-03) e exercido
/// a partir da Rodada B (fluxo de Autenticação).
///
/// O endpoint público `/auth/v1/signup` rejeita domínios reservados de
/// teste (`.test`, `example.com`) por validação de e-mail do GoTrue -
/// achado registrado na Rodada 0 (EX-10 §7). Por isso este helper usa a
/// Admin API (`/auth/v1/admin/users`), que não aplica essa validação.
///
/// A `serviceRoleKey` nunca deve ser hardcoded em nenhum arquivo deste
/// diretório - é sempre lida em tempo de execução via `--dart-define`
/// (nunca gravada em `.env.qa` nem em qualquer arquivo versionado).
class QaTestUserHelper {
  QaTestUserHelper({required this.supabaseUrl, required this.serviceRoleKey});

  final String supabaseUrl;
  final String serviceRoleKey;

  Future<String> createTestUser({
    required String email,
    required String password,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse('$supabaseUrl/auth/v1/admin/users'),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');
      request.headers.set('Content-Type', 'application/json');
      request.write(
        jsonEncode({
          'email': email,
          'password': password,
          'email_confirm': true,
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw StateError('Falha ao criar usuário de teste: $body');
      }
      return (jsonDecode(body) as Map<String, dynamic>)['id'] as String;
    } finally {
      client.close();
    }
  }

  /// Remove o usuário de teste - a cascata para `public.profiles` já foi
  /// validada na Rodada 0 (EX-10 §7).
  Future<void> deleteTestUser(String userId) async {
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(
        Uri.parse('$supabaseUrl/auth/v1/admin/users/$userId'),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');

      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode != 200) {
        throw StateError(
          'Falha ao remover usuário de teste $userId '
          '(status ${response.statusCode}).',
        );
      }
    } finally {
      client.close();
    }
  }

  /// Localiza um usuário criado pelo fluxo real de cadastro (UI), que não
  /// retorna o id ao chamador - necessário para validar "criação do
  /// usuário" e para a limpeza ao final do teste de Cadastro.
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse(
          '$supabaseUrl/auth/v1/admin/users',
        ).replace(queryParameters: {'page': '1', 'per_page': '200'}),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw StateError('Falha ao listar usuários: $body');
      }
      final users =
          ((jsonDecode(body) as Map<String, dynamic>)['users'] as List)
              .cast<Map<String, dynamic>>();
      for (final user in users) {
        if (user['email'] == email) return user;
      }
      return null;
    } finally {
      client.close();
    }
  }

  /// Consulta `public.profiles` via PostgREST usando a `service_role`
  /// (ignora RLS) - usado para validar que `handle_new_user()` criou o
  /// profile automaticamente após o cadastro.
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId&select=*'),
      );
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw StateError('Falha ao consultar profile: $body');
      }
      final rows = jsonDecode(body) as List;
      return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}
