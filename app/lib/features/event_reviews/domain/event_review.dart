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
    this.photoPath,
    this.photoUrl,
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

  /// Caminho bruto no bucket `event-review-photos` (RC-03 FASE A2,
  /// `BORAH_VISION_v2.0.md`) - exatamente 1 foto por avaliação
  /// (`photo_path`, não `photos_count` como em `reviews`, que aceita
  /// até 5). Necessário para substituir/remover a foto depois
  /// (`AppStorage.replace`/`.delete`); a UI nunca exibe isto
  /// diretamente, usa [photoUrl].
  final String? photoPath;

  /// URL assinada já resolvida de [photoPath], pronta para exibição -
  /// resolvida pelo repositório (bucket privado, escopado a membros do
  /// grupo), nunca pela tela (Capítulo 12 da Vision: formatação/
  /// resolução não é responsabilidade da apresentação... na prática
  /// aqui, resolução é responsabilidade do repositório, para que a
  /// navegação já entregue um dado pronto para renderizar).
  final String? photoUrl;

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
