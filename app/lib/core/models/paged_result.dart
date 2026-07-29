/// Resultado paginado genérico, reutilizável por qualquer módulo que
/// liste dados paginados (DV-03 §11 e futuros módulos - DV-04, DV-07 etc.).
///
/// Não carrega um total exato de registros (evita depender de uma consulta
/// de contagem à parte) - `hasNextPage` é resolvido pela camada de dados
/// buscando `limit + 1` registros e verificando se o extra veio.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.hasNextPage,
  });

  final List<T> items;
  final int page;
  final int limit;
  final bool hasNextPage;
}
