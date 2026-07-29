import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula as contagens do Dashboard (DV-08 §6) via a API de `count`
/// do PostgREST - exceção deliberada ao critério geral do projeto de não
/// depender de contagem exata (usado em `PagedResult` só para paginação,
/// onde não é necessário); aqui a contagem É o próprio produto (KPI).
class DashboardRemoteDatasource {
  DashboardRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<int> countUsers() => _count('profiles');

  Future<int> countRestaurants() => _count('restaurants');

  Future<int> countReviews() => _count('reviews');

  Future<int> countPendingReports() => _count('comment_reports');

  Future<int> _count(String table) async {
    final response = await _client
        .from(table)
        .select('id')
        .count(CountOption.exact);
    return response.count;
  }
}
