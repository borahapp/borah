import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_repository_impl.dart';
import '../domain/discovery_repository.dart';
import '../presentation/states/discovery_status.dart';

/// "Você pode conhecer" (FASE SOCIAL 2, dentro de Pesquisar/Explorar).
/// Não é paginação de verdade (as fontes são heurísticas combinadas, não
/// uma única consulta ordenável por página) - `loadMore` reexecuta com
/// um `limit` maior, mesmo princípio de "não deve ser infinito" pedido
/// (poucas sugestões por vez, nunca centenas).
class DiscoveryController extends Notifier<DiscoveryStatus> {
  @override
  DiscoveryStatus build() => const DiscoveryInitial();

  static const _initialLimit = 8;
  static const _step = 8;

  int _limit = _initialLimit;
  int _requestId = 0;

  Future<void> load(String userId) async {
    _limit = _initialLimit;
    final requestId = ++_requestId;
    state = const DiscoveryLoading();
    try {
      final repository = ref.read(discoveryRepositoryProvider);
      final result = await repository.suggestPeople(userId, limit: _limit);
      if (requestId != _requestId) return;
      state = result.people.isEmpty
          ? const DiscoveryEmpty()
          : DiscoveryLoaded(result.people, hasMore: result.hasMore);
    } on DiscoveryRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = DiscoveryError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = const DiscoveryError('Não foi possível carregar sugestões.');
    }
  }

  /// Falha aqui NÃO substitui a lista já visível por uma tela de erro
  /// (mesmo princípio de `FollowListController`/`FeedController` para
  /// falha de próxima página) - devolve `false` para a UI decidir como
  /// avisar (ex.: SnackBar), mantendo as sugestões já carregadas.
  Future<bool> loadMore(String userId) async {
    final current = state;
    if (current is! DiscoveryLoaded || !current.hasMore) return true;

    final requestId = ++_requestId;
    final nextLimit = _limit + _step;
    try {
      final repository = ref.read(discoveryRepositoryProvider);
      final result = await repository.suggestPeople(userId, limit: nextLimit);
      if (requestId != _requestId) return true;
      _limit = nextLimit;
      state = DiscoveryLoaded(result.people, hasMore: result.hasMore);
      return true;
    } catch (_) {
      return requestId == _requestId ? false : true;
    }
  }
}

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryStatus>(
      DiscoveryController.new,
    );
