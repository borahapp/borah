import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula todo acesso a `event_reviews` via PostgREST (BLOCO 4).
///
/// Sem RPC - a RLS (`event_reviews_insert_own`/`can_review_event`,
/// migration `20260801100000_create_event_reviews.sql`) já garante
/// tudo que uma função `SECURITY DEFINER` garantiria aqui: um único
/// INSERT, sem fan-out para outras tabelas (diferente de
/// `create_event()`/`create_group()`, que precisam de RPC porque
/// escrevem em duas tabelas atomicamente).
class EventReviewRemoteDatasource {
  EventReviewRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'event_reviews';
  static const _profilesTable = 'profiles';

  static const _columns =
      'id,event_id,user_id,food_score,service_score,ambience_score,'
      'cost_benefit_score,overall_score,comment';

  /// Sem embed com `profiles` - mesma limitação de
  /// `EventRemoteDatasource.fetchAttendances` (sem FK direta).
  Future<List<Map<String, dynamic>>> listByEvent(String eventId) async {
    final rows = await _client
        .from(_table)
        .select(_columns)
        .eq('event_id', eventId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Mesmo método/assinatura de `EventRemoteDatasource.fetchProfilesByIds`
  /// - duplicado aqui em vez de compartilhado, mesma decisão já tomada
  /// para todo par datasource/`profiles` do projeto.
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_profilesTable)
        .select()
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> submit({
    required String eventId,
    required String userId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  }) {
    return _client
        .from(_table)
        .insert({
          'event_id': eventId,
          'user_id': userId,
          'food_score': foodScore,
          'service_score': serviceScore,
          'ambience_score': ambienceScore,
          'cost_benefit_score': costBenefitScore,
          'overall_score': overallScore,
          'comment': comment,
        })
        .select(_columns)
        .single();
  }

  Future<Map<String, dynamic>> update({
    required String reviewId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  }) {
    return _client
        .from(_table)
        .update({
          'food_score': foodScore,
          'service_score': serviceScore,
          'ambience_score': ambienceScore,
          'cost_benefit_score': costBenefitScore,
          'overall_score': overallScore,
          'comment': comment,
        })
        .eq('id', reviewId)
        .select(_columns)
        .single();
  }
}
