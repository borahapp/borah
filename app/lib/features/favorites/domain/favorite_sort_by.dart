/// Critérios de ordenação da lista de favoritos (DV-06 §5). `rating`
/// reutiliza exatamente os mesmos critérios de desempate do DV-05 §6
/// (média desc, total de avaliações desc, mais recente desc, nome asc),
/// para manter Rankings e Favoritos consistentes.
enum FavoriteSortBy { name, rating, date }
