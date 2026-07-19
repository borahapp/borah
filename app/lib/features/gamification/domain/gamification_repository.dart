import '../../../core/models/paged_result.dart';
import 'gamification_badge.dart';
import 'ranking_entry.dart';
import 'user_progress.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class GamificationRepositoryException implements Exception {
  const GamificationRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Gamificação (DV-10). Não há método de crédito
/// de XP/pontos ou concessão de badge aqui - toda pontuação é produzida
/// exclusivamente pelos triggers do banco (mesmo princípio do DV-09); o
/// cliente só lê.
abstract interface class GamificationRepository {
  Future<UserProgress> getProgress(String userId);

  Future<List<GamificationBadge>> listAllBadges();

  Future<List<EarnedBadge>> listEarnedBadges(String userId);

  Future<PagedResult<RankingEntry>> listGlobalRanking({
    required int page,
    required int limit,
  });

  /// Fora de escopo: Ranking Mensal (sem histórico temporal) e Ranking
  /// entre Amigos antes do DV-07 existir - agora viável (decisão do DV-10).
  Future<PagedResult<RankingEntry>> listFriendsRanking(
    String userId, {
    required int page,
    required int limit,
  });
}
