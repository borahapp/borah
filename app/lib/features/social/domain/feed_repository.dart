import '../../../core/models/paged_result.dart';
import 'feed_item.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class FeedRepositoryException implements Exception {
  const FeedRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Feed (FASE SOCIAL 4 - substitui o escopo restrito
/// do DV-07 §5). Duas composições ("Model A" dinâmico, sem tabela
/// `activities`/materialized view/triggers - decisão explícita desta fase,
/// preparada para uma futura migração se o volume justificar):
///
/// - [listForYou]: descoberta determinística, sem IA/algoritmo de peso -
///   avaliações e badges de quem o usuário segue + de quem compartilha
///   grupo com ele, mais entradas recentes em grupos `public` (RPC
///   `recent_public_group_joins`). Sem preenchimento com conteúdo de
///   qualquer usuário da plataforma (decisão explícita: o Feed não deve
///   virar um mural aleatório) - se as fontes acima não renderem itens
///   suficientes, a página retorna só o que existe, nunca completa com
///   descoberta não relacionada.
/// - [listFollowing]: só avaliações e badges de quem o usuário segue.
///
/// Itens são combinados e ordenados por `(createdAt desc, feedKey desc)`
/// dentro da camada de dados (`FeedRepositoryImpl`) - `page`/`limit`
/// continuam sendo OFFSET sobre esse conjunto já mesclado, mesmo padrão de
/// `PagedResult` usado pelo resto do projeto (sem cursor nesta fase).
abstract interface class FeedRepository {
  Future<PagedResult<FeedItem>> listForYou(
    String userId, {
    required int page,
    required int limit,
  });

  Future<PagedResult<FeedItem>> listFollowing(
    String userId, {
    required int page,
    required int limit,
  });
}
