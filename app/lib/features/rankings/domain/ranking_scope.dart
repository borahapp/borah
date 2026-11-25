/// Escopo do Ranking de restaurantes (Item F - ranking multi-escopo).
/// `global`: todos os restaurantes, por nota média pública (DV-05,
/// comportamento original). `personal`: só os restaurantes que o próprio
/// usuário avaliou, pela nota que ele mesmo deu. `group`: restaurantes
/// dos rolês de um grupo específico, pela média das avaliações coletivas
/// desses rolês.
enum RankingScope { global, personal, group }
