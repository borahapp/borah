/// Avaliação coletiva de um participante sobre um rolê (BLOCO 4) - 5
/// critérios (comida/atendimento/ambiente/custo-benefício/experiência
/// geral), escala 1 a 5, mesmo formato de `reviews.rating` (DV-04).
/// `fullName`/`avatarUrl` vêm de `profiles`, mesma limitação de
/// `EventAttendance` (sem FK direta entre `event_reviews` e `profiles`).
class EventReview {
  const EventReview({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.foodScore,
    required this.serviceScore,
    required this.ambienceScore,
    required this.costBenefitScore,
    required this.overallScore,
    required this.comment,
    required this.fullName,
    required this.avatarUrl,
  });

  final String id;
  final String eventId;
  final String userId;
  final double foodScore;
  final double serviceScore;
  final double ambienceScore;
  final double costBenefitScore;
  final double overallScore;
  final String? comment;
  final String? fullName;
  final String? avatarUrl;

  /// "Nota final" desta avaliação individual - média simples dos 5
  /// critérios (mesma decisão de pesos iguais registrada na migration
  /// `20260801100000_create_event_reviews.sql`). O agregado do rolê
  /// (`Event.averageRating`) é a média disto entre todos os
  /// participantes, calculada no banco (trigger), nunca aqui.
  double get averageScore =>
      (foodScore +
          serviceScore +
          ambienceScore +
          costBenefitScore +
          overallScore) /
      5;
}
