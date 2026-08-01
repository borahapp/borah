/// `firstWhereOrNull` mínimo (BLOCO 9) - `package:collection` não é
/// dependência deste projeto (confirmado por busca antes de introduzir
/// isto), e o mesmo loop manual (buscar "o item próprio" de uma lista
/// por `userId`) já tinha sido copiado 4 vezes (`GroupDetails.ownRole`,
/// `EventDetails.ownAttendance`, `EventDetailPage._findOwnReview`,
/// `GroupStatsPage._findOwn`) - acima do limiar de duplicação tolerado
/// neste projeto (3 cópias). Nenhuma abstração maior que isto: só a
/// função que já existia repetida, extraída uma vez.
T? firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
