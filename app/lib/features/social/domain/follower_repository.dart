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

  /// FASE SOCIAL 1 - busca de pessoas (nova tela de Pesquisa). `ilike`
  /// sobre `profiles.full_name`, mesmo padrão já usado em
  /// `RestaurantRepository.search` - sem `username` (coluna ainda não
  /// existe) e sem índice trigram (volume atual do projeto não exige).
  Future<PagedResult<UserProfile>> searchProfiles(
    String query, {
    required int page,
    required int limit,
  });
}
