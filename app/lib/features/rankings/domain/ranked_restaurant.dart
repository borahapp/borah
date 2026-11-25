/// Uma linha do Ranking de restaurantes (Item F - ranking multi-escopo),
/// independente do [RankingScope] que a produziu. Deliberadamente NÃO é o
/// `Restaurant` do DV-03: `rating`/`reviewsCount` aqui são relativos ao
/// escopo (nota média pública no `global`, a própria nota do usuário no
/// `personal` - sem contagem, por isso [reviewsCount] nulável -, média das
/// avaliações coletivas do grupo no `group`), nunca os campos globais
/// `Restaurant.averageRating`/`totalReviews`. Guarda só o que o
/// `RankingCard` e a navegação para `/restaurants/:id` precisam - as 3
/// fontes (tabela `restaurants`, embed `reviews.restaurants`, RPC
/// `get_group_restaurant_ranking`) convergem para este único formato.
class RankedRestaurant {
  const RankedRestaurant({
    required this.restaurantId,
    required this.name,
    required this.category,
    this.city,
    this.state,
    this.country,
    this.coverImage,
    required this.rating,
    this.reviewsCount,
  });

  final String restaurantId;
  final String name;
  final String category;
  final String? city;
  final String? state;
  final String? country;
  final String? coverImage;
  final double rating;

  /// `null` no escopo `personal` (uma avaliação só, "sua nota" não tem
  /// contagem que valha a pena mostrar).
  final int? reviewsCount;
}
