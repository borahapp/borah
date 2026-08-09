import '../../users/domain/user_profile.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class DiscoveryRepositoryException implements Exception {
  const DiscoveryRepositoryException(this.message);

  final String message;
}

class DiscoverySuggestions {
  const DiscoverySuggestions({required this.people, required this.hasMore});

  final List<UserProfile> people;
  final bool hasMore;
}

/// FASE SOCIAL 2 - "Você pode conhecer" (Pesquisa/Explorar). Sem
/// tabela/RPC/algoritmo novo: combina 2 fontes já cobertas pela RLS
/// existente (ver AUDITORIA — FASE SOCIAL 2 §8/§13/§14) - pessoas do
/// mesmo grupo (prioridade 1) e seguidores de quem o usuário já segue
/// (prioridade 2, "amigos de amigos"), sem machine learning e sem
/// localização.
abstract interface class DiscoveryRepository {
  Future<DiscoverySuggestions> suggestPeople(
    String userId, {
    required int limit,
  });
}
