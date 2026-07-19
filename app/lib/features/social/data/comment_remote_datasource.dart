import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula toda a construção de consultas PostgREST das tabelas
/// `comments` e `comment_reports` (DV-07). Nenhuma camada acima desta
/// conhece esses detalhes (mesma decisão do DV-03 em diante).
class CommentRemoteDatasource {
  CommentRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'comments';
  static const _reportsTable = 'comment_reports';

  /// Busca `limit + 1` registros para permitir detectar se há próxima
  /// página sem depender de uma contagem exata (core/models/paged_result.dart).
  Future<List<Map<String, dynamic>>> listByReview(
    String reviewId, {
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    final rows = await _client
        .from(_table)
        .select()
        .eq('review_id', reviewId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) {
    return _client.from(_table).insert(data).select().single();
  }

  /// Sujeito à janela de 15 minutos reforçada por trigger no banco - uma
  /// tentativa fora do prazo retorna um erro do Postgrest, traduzido pelo
  /// repositório.
  Future<Map<String, dynamic>> updateContent(String id, String content) {
    return _client
        .from(_table)
        .update({'content': content})
        .eq('id', id)
        .select()
        .single();
  }

  Future<void> softDelete(String id) {
    return _client
        .from(_table)
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> report(String commentId, String reportedBy, String reason) {
    return _client.from(_reportsTable).insert({
      'comment_id': commentId,
      'reported_by': reportedBy,
      'reason': reason,
    });
  }
}
