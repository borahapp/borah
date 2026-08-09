import '../../../core/models/paged_result.dart';
import '../../users/domain/user_profile.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class FollowerRepositoryException implements Exception {
  const FollowerRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio de Seguidores (DV-07). Reaproveita `UserProfile`
/// (DV-02) - sem entidade `Follower` própria, mesmo padrão de reuso já
/// aplicado a `Restaurant` (DV-05/06) e `Review` (este módulo, no Feed).
abstract interface class FollowerRepository {
  Future<void> follow(String followerId, String followingId);

  Future<void> unfollow(String followerId, String followingId);

  Future<bool> isFollowing(String followerId, String followingId);

  Future<PagedResult<UserProfile>> listFollowers(
    String userId, {
    required int page,
    required int limit,
  });

  Future<PagedResult<UserProfile>> listFollowing(
    String userId, {
    required int page,
    required int limit,
  });

  /// Busca de pessoas (Pesquisa/Explorar). `ilike` sobre
  /// `profiles.full_name` OU `profiles.username` (FASE SOCIAL 2 - aceita
  /// "victor" e "@victorfrare"), sem índice trigram (volume atual do
  /// projeto não exige).
  Future<PagedResult<UserProfile>> searchProfiles(
    String query, {
    required int page,
    required int limit,
  });

  /// FASE SOCIAL 2 - quais de [candidateIds] o usuário [followerId] já
  /// segue, numa única consulta. Usada para popular o botão
  /// Seguir/Seguindo em listas (resultados de busca, seguidores/
  /// seguindo, sugestões) sem 1 consulta por linha.
  Future<Set<String>> listFollowingAmong(
    String followerId,
    List<String> candidateIds,
  );
}
