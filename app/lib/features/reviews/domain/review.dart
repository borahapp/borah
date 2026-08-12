/// Entidade de avaliação (DV-04 §9) — avaliação por restaurante, sem
/// vínculo com evento (decisão que ignora o modelo do ET-08).
///
/// `rating` é a nota geral — RC-03 F16 passou a alimentá-la como a média
/// dos 4 critérios abaixo (mesmo padrão de `event_reviews`), mas a coluna
/// nunca foi removida/renomeada (compatibilidade com avaliações antigas).
/// Os 4 campos de critério são nulos em avaliações criadas antes do F16 —
/// nenhuma migração retroativa de dado foi feita.
class Review {
  const Review({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.rating,
    this.ambienceScore,
    this.serviceScore,
    this.foodScore,
    this.costBenefitScore,
    this.comment,
    required this.likesCount,
    required this.photosCount,
    required this.createdAt,
    required this.updatedAt,
    this.authorFullName,
    this.authorAvatarUrl,
    this.restaurantName,
    this.restaurantCoverImage,
  });

  final String id;
  final String restaurantId;
  final String userId;
  final double rating;
  final double? ambienceScore;
  final double? serviceScore;
  final double? foodScore;
  final double? costBenefitScore;
  final String? comment;
  final int likesCount;
  final int photosCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Resolvidos separadamente pelo repositório (2B.3) - `reviews.user_id`
  /// referencia `auth.users`, sem FK direta para `profiles` (mesma
  /// limitação já documentada/corrigida no Feed), então nunca vêm
  /// embutidos na linha de `reviews` - só populados quando o repositório
  /// os resolveu (ex.: chamadas de listagem/detalhe), `null` quando não
  /// aplicável.
  final String? authorFullName;
  final String? authorAvatarUrl;

  /// `reviews.restaurant_id` tem FK direta para `restaurants.id` - estes
  /// vêm de um embed PostgREST válido, sempre presentes junto com a
  /// própria linha quando resolvidos pelo repositório.
  final String? restaurantName;
  final String? restaurantCoverImage;

  /// `true` quando a avaliação tem os 4 critérios (criada/editada pela UI
  /// pós-F16) — usado pela UI para decidir entre mostrar o detalhamento
  /// por critério ou só a nota geral (avaliações legadas).
  bool get hasCriteriaScores =>
      ambienceScore != null &&
      serviceScore != null &&
      foodScore != null &&
      costBenefitScore != null;
}
