import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../data/gamification_repository_impl.dart';
import '../domain/gamification_repository.dart';
import '../domain/ranking_entry.dart';
import '../presentation/states/ranking_users_status.dart';

/// Ranking de Usuários (DV-10 §5): Global e Entre Amigos via um único
/// método parametrizado, mesmo padrão do `FollowListController` (DV-07).
class RankingUsersController extends Notifier<RankingUsersStatus> {
  @override
  RankingUsersStatus build() => const RankingUsersInitial();

  GamificationRepository get _repository =>
      ref.read(gamificationRepositoryProvider);

  String? _userId;
  RankingUsersType _type = RankingUsersType.global;
  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> load(String userId, RankingUsersType type) {
    _userId = userId;
    _type = type;
    _page = 1;
    return _run(const RankingUsersLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! RankingUsersLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `FeedController._run`): só a resposta cujo `requestId` ainda bate com
  /// `_requestId` no momento em que o fetch resolve pode escrever em
  /// `state` - evita que um `loadNextPage` disparado durante um `load`
  /// (ex.: trocar de Global para Amigos com o scroll perto do fim) produza
  /// um resultado final inconsistente, qualquer que seja a ordem das
  /// respostas.
  Future<void> _run(
    RankingUsersStatus loadingState, {
    List<RankingEntry> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = _type == RankingUsersType.global
          ? await _repository.listGlobalRanking(page: _page, limit: _limit)
          : await _repository.listFriendsRanking(
              _userId!,
              page: _page,
              limit: _limit,
            );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const RankingUsersEmpty()
          : RankingUsersLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on GamificationRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      // Reverte `_page`: a página que falhou nunca chegou a ser aplicada,
      // então a próxima tentativa deve rebuscá-la, em vez de pular para a
      // seguinte.
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = RankingUsersError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const RankingUsersError('Não foi possível carregar o ranking.');
    }
  }
}

final rankingUsersControllerProvider =
    NotifierProvider<RankingUsersController, RankingUsersStatus>(
      RankingUsersController.new,
    );
